% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bm-placebo.R
\docType{data}
\name{placebo}
\alias{placebo}
\title{Placebo benchmark for testing}
\format{
An object of class \code{Benchmark} of length 9.
}
\usage{
placebo
}
\description{
Placebo benchmark for testing
}
\section{Parameters}{

\itemize{
\item \code{duration} the duration for the benchmark to take
\item \code{error_type} \code{NULL} to cause no error, \code{"rlang::abort"} to use rlang's
\code{abort} and any other string (including \code{"base"}) will use base's \code{stop}
}
}

\keyword{internal}
