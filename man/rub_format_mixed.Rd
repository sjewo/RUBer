% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utility.R
\name{rub_format_mixed}
\alias{rub_format_mixed}
\title{Format flextable mixed type columns (integer, percentages, NAs)}
\usage{
rub_format_mixed(x)
}
\arguments{
\item{x}{Vector}
}
\value{
Formatted vector
}
\description{
Format flextable mixed type columns (integer, percentages, NAs)
}
\examples{
x <- c("2500", "0.29", NA)
rub_format_mixed(x)
}
