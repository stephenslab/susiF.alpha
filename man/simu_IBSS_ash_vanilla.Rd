% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Simulations_functions.R
\name{simu_IBSS_ash_vanilla}
\alias{simu_IBSS_ash_vanilla}
\title{Simulate data under the mixture normal prior}
\usage{
simu_IBSS_ash_vanilla(lev_res = 7, length_grid = 10, pi0 = 0.85)
}
\arguments{
\item{lev_res}{numerical corresponds to the resolution of the simulated function (idealy between 3 and 10)}

\item{length_grid}{vector numerical corresponds to the length of the grid of sigma for mixture component(cf ash)}

\item{piO}{vector numerical , contain a digit  between 0 and 1, which corresponds to the null proportion ( non assocatied wavelet coefficients)}
}
\description{
Add description here.
}
\examples{

out <- simu_IBSS_ash_vanilla(lev_res=8, length_grid= 10, pi0= 0.85)
plot(out$sim_func, type="l", ylab="y")
out$emp_pi0
}
