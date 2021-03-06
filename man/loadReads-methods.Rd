% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/methods-segvis.R
\docType{methods}
\name{loadReads}
\alias{loadReads}
\alias{loadReads,segvis,numeric-method}
\title{loadReads method for segvis class}
\usage{
loadReads(object, mc)

\S4method{loadReads}{segvis,numeric}(object, mc)
}
\arguments{
\item{object}{segvis object}

\item{mc}{numeric, the number of cores used with parallel}
}
\value{
segvis object
}
\description{
Load the fragment stored in the file slot of the segvis object. The reads are divided by chromosome and by strand.
}
\examples{
\dontrun{

segvis <- loadReads(segvis,mc=8)

}
}
\seealso{
\code{\link{readsF}}, \code{\link{readsR}} and \code{\link{reads-class}}
}

