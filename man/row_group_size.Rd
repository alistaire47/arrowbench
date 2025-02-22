% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bm-row-group-size.R
\docType{data}
\name{row_group_size}
\alias{row_group_size}
\title{Benchmark effect of parquet row group size}
\format{
An object of class \code{Benchmark} of length 9.
}
\usage{
row_group_size
}
\description{
Benchmark effect of parquet row group size
}
\section{Parameters}{

\itemize{
\item \code{source} A known-file id, or a file path to read in
\item \code{queries} What queries to run
\item \code{chunk_size} Number of rows to write in each row group. Suggested sizes:
\code{chunk_size = list(NULL, 10000L, 100000L, 1000000L)}
}
}

\keyword{datasets}
