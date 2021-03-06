% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mbm.r
\name{mbm}
\alias{mbm}
\title{Create an mbm model}
\usage{
mbm(y, x, y_name = "beta", link = c("identity", "probit"),
  likelihood = c("gaussian"), lengthscale = NULL, sparse = FALSE,
  force_increasing = FALSE, sparse_inducing = 10, sparse_batch = 10,
  sparse_iter = 10000, exact_thresh = 100, verbose = FALSE)
}
\arguments{
\item{y}{Square dissimilarity or distance matrix, can be complete or lower triangular 
only. Row and column names are required and must match the site names in the 
rows of \code{x}.}

\item{x}{Matrix giving a series of covariates (in columns) for all sites (in rows). Row 
names are required. All variables will be included in the model.}

\item{y_name}{A name to give to the y variable}

\item{link}{Link function to use}

\item{likelihood}{Likelihood function to use}

\item{lengthscale}{Either NULL (in which case all lengthscales will be optimized) or 
a numeric vector of length \code{ncol(x)+1}. If a vector, the first entry 
    corresponds to environmental distance, and entries \code{i = 1 + (1:n)} 
    correspond to the variable in x[,i]. Values must be \code{NULL} or positive 
    numbers; if NULL, the corresponding lengthscale will be set via optimization, 
    otherwise it will be fixed to the value given.}

\item{sparse}{Should we use the stochastic variational GP (see 'details').}

\item{force_increasing}{Boolean; if true, beta diversity will be constrained to 
increase with environmental distance}

\item{sparse_inducing}{Number of inducing inputs to use if `sparse = TRUE`}

\item{sparse_batch}{Batch size to use if `sparse = TRUE`}

\item{sparse_iter}{Maximum number of optimizer iterations if `sparse = TRUE`}

\item{exact_thresh}{integer; threshold at which mbm will refuse to run an exact gp.}

\item{verbose}{Should messages during model fitting be printed?}
}
\value{
An S3 object of class mbm, containing the following components:
	* `x`: the original (untransformed) site by covariate matrix
* `y`: the original (untransformed) site by site diversity data
 * `covariates`: Transformed x-variables supplied to mbm
 * `response`: Transformed response variable; this is the data supplied to mbm
 * `covar_sites`: Site names to match the covariate matrix
 * `y_transform`: transformation applied to y-data before modelling
 * `y_rev_transform`: reverse transformation to get y-data back on the original scale
 * `link`: a character string identifying the link function
 * `inv_link`: inverse of the link function
 * `pyobj`: A list of python objects used by the model; this is not meant for user interaction
}
\description{
Create an mbm model
}
\details{
For larger datasets (more than ~100 sites), it is recommended to use
			`sparse=TRUE`. This will use a sparse approximation to the default
			method, following the stochastical variational GP (Hensman et al 2013).
			Note that if a link function is selected, it will be applied as a 
			transformation of the y data--i.e., for link function L() we fit a SVGP to
			describe the expectation E(L(y))--rather than as a true link function--
			fitting L(E(y))--as is done when `svgp=FALSE`. This is due to a 
			limitation in the underlying GP library.
}
\references{
Hensman J, Fusi N, and Lawrence ND. 2013. Gaussian Processes for Big Data.
			In: In Proceedings of the 29th Conference on Uncertainty in Artificial 
			Intelligence.
}
