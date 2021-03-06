% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/operation_on_susiF_obj.R
\name{discard_cs}
\alias{discard_cs}
\title{Discard credible sets}
\usage{
discard_cs(susiF.obj, cs)
}
\arguments{
\item{susiF.obj}{a susif object defined by \code{\link{init_susiF_obj}} function}

\item{cs}{vector of integer containing the credible sets to discard}
}
\value{
a susif.obj without "dummy" credible sets
}
\description{
Discard credible sets
}
