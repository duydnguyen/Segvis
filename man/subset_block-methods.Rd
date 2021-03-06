% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/methods-segvis_block.R
\docType{methods}
\name{subset_block}
\alias{subset_block}
\alias{subset_block,ANY-method}
\alias{subset_block,segvis_block-method}
\title{subset_block method for segvis_block class}
\usage{
subset_block(object, condition)

\S4method{subset_block}{segvis_block}(object, condition)
}
\arguments{
\item{object}{segvis_block object}

\item{condition}{This is an expression considering the characteristics taht the subset need to satisfy}
}
\value{
Returns a segvis_block object with the same parameters as object except regions and cover_table which are filtered to satisfy the conditions on condition.
}
\description{
This method works similarly to the subset of IRanges, GenomicRanges, GenomicAlignments, etc. Althought it doesn't consider the select parameter.
}
\examples{
\dontrun{

subset_block(segvis_block, cond == TRUE)

}
}
\seealso{
\code{\link{segvis_block-class}}
}

