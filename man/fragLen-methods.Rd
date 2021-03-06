% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/AllGenerics.R, R/methods-segvis.R
\docType{methods}
\name{fragLen}
\alias{fragLen}
\alias{fragLen,segvis-method}
\alias{fragLen<-}
\alias{fragLen<-,segvis,numeric-method}
\title{fragLen methods}
\usage{
fragLen(object)

fragLen(object) <- value

\S4method{fragLen}{segvis}(object)

\S4method{fragLen}{segvis,numeric}(object) <- value
}
\arguments{
\item{object}{A \code{segvis} object}

\item{value}{A numeric value representing the fragment length}
}
\value{
A integer value

A segvis object
}
\description{
fragLen returns a numeric value representing the fragment length used to extend the fragment reads in the Single Ended case (i.e. isPET = FALSE)

fragLen<- assigns an integer value representing the bp to extend the fragments in SET case
}
\examples{
\dontrun{

fragLen(segvis)
fragLen(segvis) <- 200

}
}
\seealso{
\code{\link{segvis-class}}
}

