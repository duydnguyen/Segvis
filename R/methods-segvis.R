
# Methods for profile class

## Get methods

#' @rdname methods-segvis-gs
#' @name name 
setMethod("name",
  signature = signature(object = "segvis"),
  definition = function(object)object@name
)           

#' @rdname methods-segvis-gs
#' @name regions
setMethod("regions",
  signature = signature(object = "segvis"),
  definition = function(object)object@regions
)           

#' @rdname methods-segvis-gs
#' @name file
setMethod("file",
  signature = signature(object = "segvis"),
  definition = function(object)object@file
)           

#' @rdname methods-segvis-gs
#' @name maxBandwidth
setMethod("maxBandwidth",
  signature = signature(object = "segvis"),
  definition  = function(object)object@maxBandwidth
)           

#' @rdname methods-segvis-gs
#' @name fragLen
setMethod("fragLen",
  signature = signature(object = "segvis"),
  definition = function(object)object@fragLen
)           

#' @rdname methods-segvis-gs
#' @name readsF
setMethod("readsF",
  signature = signature(object = "segvis"),
  definition = function(object)readsF(object@reads)
)           

#' @rdname methods-segvis-gs
#' @name readsR
setMethod("readsR",
  signature = signature(object = "segvis"),
  definition = function(object)readsR(object@reads)
)

#' @rdname methods-segvis-gs
#' @name matchF
setMethod("matchF",
  signature = signature(object = "segvis"),
  definition = function(object)matchF(object@match)
)

#' @rdname methods-segvis-gs
#' @name matchR
setMethod("matchR",
  signature = signature(object = "segvis"),
  definition = function(object)matchR(object@match)
)

#' @rdname methods-segvis-gs
#' @name profileCurve
setMethod("profileCurve",
  signature = signature(object = "segvis"),
  definition = function(object)object@profileCurve
)  

## Set methods

#' @rdname methods-segvis-gs
#' @name name<-
setReplaceMethod("name",
  signature = signature(object = "segvis",value = "character"),
  definition = function(object,value){
    object@name = value
    return(object)
})
   
#' @rdname methods-segvis-gs
#' @name regions<-
setReplaceMethod("regions",
  signature = signature(object = "segvis",value = "GRanges"),
  definition = function(object,value){
    stopifnot(class(value) == "GRanges")
    object@regions = value
    object@.haveRegions = TRUE
    return(object)
})

#' @rdname methods-segvis-gs
#' @name file<-
setReplaceMethod("file",
  signature = signature(object = "segvis",value = "character"),
  definition = function(object,value){
    stopifnot(class(value) == "character")
    object@file = value
    return(object)
})    

#' @rdname methods-segvis-gs
#' @name maxBandwidth<-
setReplaceMethod("maxBandwidth",
  signature = signature(object = "segvis", value = "numeric"),
  definition = function(object,value){
    stopifnot(value >= 1)
    stopifnot(value %% 2 == 1)
    object@maxBandwidth = value
    return(object)
})    

#' @rdname methods-segvis-gs
#' @name fragLen<-
setReplaceMethod("fragLen",
  signature = signature(object = "segvis", value = "numeric"),
  definition = function(object,value){
    stopifnot(value >= 0)
    stopifnot(value == floor(value))
    object@fragLen = value
    return(object)
})    

#' @rdname methods-segvis-show
#' @name show
setMethods("show",
  signature = signature(object = "segvis"),
  definition = function(object){
#    cat("---------------------------\n")
    cat("Profile for",name(object),"regions\n")
    cat("Fragment length:",fragLen(object),"\n")
    cat("Max Bandwidth:", maxBandwidth(object),"\n")
    cat("Using reads files:\n")
    cat(file(object),sep = "\n")
    len = length(seqlengths(regions(object)))
    if( len > 0){
      cat("Using regions for",len,"chromosomes\n")
      show(regions(object))      
    }else{
      cat("**Not regions loaded**\n")
    }
#    cat("---------------------------\n")
})
          
# @rdname profile-methods
# @name loadReads
# @aliases profile
setMethods("loadReads",
  signature = signature(object = "profile",mc = "numeric"),
  definition = function(object,mc ){
    if(fileFormat(object) == "bam"){    
      chr = names(seqlengths(regions(object)))
      if(length(remChr(object)>1))
      {                
        chr = chr[!chr %in% remChr(object)]       
      }else{
        if(remChr(object) != "")chr = chr[!chr %in% remChr(object)]
      }
      message("Reading ",file(object))
      param = ScanBamParam(which = regions(object))
      greads = readGAlignmentsFromBam(file(object),param = param,use.names = FALSE)
      u = gc()
      greads = as(greads, "GRanges")      
      seqlevels(greads) = seqlevelsInUse(greads)      
      if(any(unique(seqnames(greads)) %in% remChr(object) )){
        warning("There exists reads with seqnames in remChr(object)")
      }
      seqlevels(greads,force =TRUE) =seqlevels(regions(object))  
      message("Bam file loaded")
      message("Separating by chromosome")      
      greads = mclapply(chr,function(i,greads)
        subset(greads, subset = as.character(seqnames(greads)) == i),greads,mc.cores = mc)
      names(greads) = chr
      message("Separating reads by strand")
      gr1 = mclapply(greads,function(x).sort_by_strand(subset(x,subset = as.character(strand(x))=="+"),"+"),
        mc.cores = mc)
      message("Forward strand reads extracted")
      gr2 = mclapply(greads,function(x).sort_by_strand(subset(x,subset = as.character(strand(x))=="-"),"-"),
        mc.cores = mc)
      message("Reverse strand reads extracted")
      message("Finished separating reads")
      gr1 = GRangesList(gr1)
      gr2 = GRangesList(gr2)
      object@reads = new("reads",readsF = gr1,readsR = gr2)
      object@.haveReads = TRUE
      message("Reading bam files... Done")
      return(object)
    }else{# Change warning
      warning("loadReads method only defined for bam file format")
    }
})

# @rdname profile-methods
# @name matchReads
# @aliases profile
setMethods("matchReads",
  signature = signature(object = "profile",mc = "numeric"),
  definition = function(object,mc = 8){
    if(object@.haveReads & object@.haveRegions){    
      side = (maxBandwidth(object)-1)/2      
      chr = names(seqlengths(regions(object)))
      regions = lapply(chr,function(chrom,reg){
        subset(reg,subset = as.character(seqnames(reg)) == chrom)
      },regions(object))
      regions = GRangesList(lapply(regions,function(x)
        trim(GRanges(seqnames = seqnames(x),ranges = IRanges(start = start(x) - side,
          end = end(x) + side),strand = strand(x)))))
      names(regions) = chr      
      if(length(remChr(object)>1))
      {                
        chr = chr[!chr %in% remChr(object)]       
      }else{
        if(remChr(object) != "")chr = chr[!chr %in% remChr(object)]
      }
      message("Matching reads for forward strand")
      m1 = mclapply(chr,function(chrom,reads,reg,object){
        message("Matching forward reads for ",chrom)
        overlaps = findOverlaps(reg[[chrom]],resize(reads[[chrom]],fragLen(object)))       
        mm = lapply(1:length(reg[[chrom]]),
          function(i,overlaps)subjectHits(subset(overlaps,subset = queryHits(overlaps) == i)),
          overlaps)  
        message("Forward strand matching for ",chrom," done");return(mm)},
        readsF(object),regions,object,mc.cores = mc)
      names(m1) = chr            
      message("Forward strand done")
      message("Matching reads for reverse strand")
      m2 = mclapply(chr,function(chrom,reads,reg,object){
        message("Matching reverse reads for ",chrom)
        overlaps = findOverlaps(reg[[chrom]],resize(reads[[chrom]],fragLen(object)))
        mm = lapply(1:length(reg[[chrom]]),
          function(i,overlaps)subjectHits(subset(overlaps,subset = queryHits(overlaps) == i)),
          overlaps)
        message("Reverse strand matching for ",chrom," done");return(mm)},
        readsR(object),regions,object,mc.cores = mc)
      names(m2) = chr
      message("Reverse strand done")
      object@match = new("match",matchF = m1,matchR = m2)
      object@.readsMatched = TRUE
     return(object)      
    }else{
      warning("Check that both reads and regions are loaded")
    }
})

# @rdname profile-methods
# @name getCoverage
# @aliases profile
setMethods("getCoverage",
  signature = signature(object = "profile",mc = "numeric"),
  definition = function(object, mc = 8){
    if(object@.readsMatched == TRUE){      
      chr = names(seqlengths(regions(object)))
      if(length(remChr(object)>1))
      {                
        chr = chr[!chr %in% remChr(object)]       
      }else{
        if(remChr(object) != "")chr = chr[!chr %in% remChr(object)]
      }
      ll = lapply(chr,function(chrom,reg){
        length(subset(reg,subset = as.character(seqnames(reg)) == chrom))
      },regions(object))
      names(ll) = chr           
      curve = lapply(chr,function(chrom,object,ll,mc){
        message("Retrieving reads for ",chrom)        
        l = ll[[chrom]]
        r1 = readsF(object)[[chrom]]
        r2 = readsR(object)[[chrom]]
        m1 = matchF(object)[[chrom]]
        m2 = matchR(object)[[chrom]]
        message("Calculating coverage for ",chrom)
        z = mclapply(1:l,function(i,r1,r2,m1,m2){
          coverage(c(resize(r1[m1[[i]]],fragLen(object)),
                     resize(r2[m2[[i]]],fragLen(object))))[[chrom]]}
                 ,r1,r2,m1,m2,mc.cores = mc)        
        message("Coverage calculated for ",chrom)
        return(z)},
        object,ll,mc)     
      names(curve) = chr
      object@profileCurve = curve
      object@.coverageCalculated = TRUE
      message("Coverage done")
      return(object)     
    }else{
      warning("The reads haven't been matched yet")
    }
})    

# @rdname profile-methods
# @name buildProfileMatrix
# @aliases profile
setMethods("buildProfileMatrix",
  signature = signature(object = "profile",bw = "numeric",mc = "numeric"),
  definition = function(object,bw,mc=8){
  if(length(unique(width(regions(object))))>1){
      stop("The width of the regions isn't unique, can't build profile matrix")
  }  
  message("Calculating profiles for each chromosome")
  matList = .calculateMAprofile(object,bw,mc)
  message("Joining profiles into matrix")
  matList = lapply(matList,function(x)do.call(rbind,x))
  matList = do.call(rbind,matList)
  message("Profile matrix built")
  return(matList)
})    

# @rdname profile-methods
# @name findSummit
# @aliases profile
setMethods("findSummit",          
  signature = signature(object = "profile",bw = "numeric",mc = "numeric"),
  definition = function(object,bw,mc=8){
  message("Calculating profiles for each chromosome")
  matList = .calculateMAprofile(object,bw,mc)
  message("Finding summits for each chromosome")
  chr = names(seqlengths(regions(object)))
  if(length(remChr(object)>1))
  {                
    chr = chr[!chr %in% remChr(object)]       
  }else{
    if(remChr(object) != "")chr = chr[!chr %in% remChr(object)]
  }
  regions = lapply(chr,function(chrom,reg){
        subset(reg,subset = as.character(seqnames(reg)) == chrom)
      },regions(object))
  names(regions) = chr
  summits_chr = lapply(chr,function(chrom,regions,matList){
    message("Finding summit for regions of ",chrom)    
    reg = regions[[chrom]]
    ll = length(reg)
    rStart = start(reg)
    rEnd = end(reg)
    mat = matList[[chrom]]
    z = mclapply(1:ll,function(i,mat,rStart,rEnd){
      if(all(is.na(mat[[i]]))){
        summit = NA
      }else{
        x = seq(rStart[i],rEnd[i],by = 1)
        summit = x[which.max(mat[[i]])]
      }
      return(summit)
    },mat,rStart,rEnd)
    return(unlist(z))         
  },regions,matList)
  return(unlist(summits_chr))    
})

# @rdname profile-methods
# @name normConst
# @aliases profile
setMethods("countReads",
  signature = signature(object = "profile"),
  definition = function(object){   
    reader = bamReader(file(object),idx=TRUE)
    readMatrix = bamCountAll(reader)
    counts = sum(readMatrix$nAligns)
    return(counts)  
})

# @rdname profile-methods
# @name ProfileMatrix
# @aliases profile
setMethods("ProfileMatrix",
  signature = signature(object = "profile",bw = "numeric",mc = "numeric"),
  definition = function(object,bw,mc){    
    mat = buildProfileMatrix(object,bw,mc)
    nc = countReads(object)
    nm = name(object)
    gr = regions(object)
    pmatrix = new("profileMatrix",name = nm,regions = gr,profileMat = mat,bandwidth = bw,normConst = nc)
    return(pmatrix)
})    