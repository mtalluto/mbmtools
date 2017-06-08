#' Construct (but do not fit) an mbm model
#' 
#' @param x Matrix giving a series of covariates (in columns) for all sites (in rows). Row names are required. All 
#'          variables will be included in the model.
#' @param y Square dissimilarity or distance matrix, can be complete or lower triangular only. Row and column names are
#'          required and must match the site names in the rows of \code{x}.
#' @param y_name A name to give to the y variable
#' @param predictX List of prediction datasets; each list element is a matrix with same number of columns as \code{x}
#' @param link Link function to use
#' @param scale Boolean, if true, x values will be centered and scaled before fitting the model.
#' @param lengthscale Either missing (in which case all lengthscales will be optimized) or a numeric vector of length \code{ncol(x)+1}.
#'         If a vector, the first entry corresponds to environmental distance, and entries \code{i = 1 + (1:n)} correspond to the variable in 
#'         x[,i]. Values must be \code{NA} or positive numbers; if NA, the corresponding lengthscale will be set via optimization, otherwise
#'         it will be fixed to the value given.
#' @param force_increasing Boolean; if true, beta diversity will be constrained to increase with environmental distance
#' @param response_curve The type of response curve to generate. The default (\code{distance}) will predict over a range of distances
#'          assuming pairs of sites equally spaced across the midpoint of environmental space. \code{none} Produces no response curve,
#'          while \code{all} creates response curves for all variables.
#' @return An mbm object
#' @keywords internal
make_mbm <- function(x, y, y_name, predictX, link, scale, lengthscale, force_increasing, response_curve)
{
	model <- list()
	class(model) <- c('mbm', class(model))
	attr(model, 'y_name') <- y_name
	
	## process covariates
	if(scale) {
		x <- scale(x)
		model$x_scaling = function(xx) scale(xx, center = attr(x, "scaled:center"), scale = attr(x, "scaled:scale"))
		model$x_unscaling = function(xx) xx*attr(x, "scaled:scale") + attr(x, "scaled:center")
	}
	xDF <- env_dissim(x)
	
	## process response transformation & mean function
	yDF <- reshape2::melt(y,varnames=c('site1', 'site2'), value.name = y_name)
	dat <- merge(xDF, yDF, all.x = TRUE)

	model$y_transform <- model$y_rev_transform <- function(y) y
	if(force_increasing)
	{
		if(link != 'identity')
		{
			model <- set_ytrans(model, dat[,y_name], link)
			link <- 'identity'
			dat[,y_name] <- model$y_transform(dat[,y_name])
		}
		attr(model, "mean_function") <- "linear_increasing"
	} else
		attr(model, "mean_function") <- 0

	## add data to obj
	x_cols <- which(!colnames(dat) %in% c('site1', 'site2', y_name))
	model$response <- dat[,y_name]
	model$covariates <- dat[,x_cols]
	
	## lengthscales
	if(!missing(lengthscale))
	{
		if(length(lengthscale) != ncol(model$covariates) | !(all(lengthscale > 0 | is.na(lengthscale))))
			stop("Invalid lengthscale specified; see help file for details")
		model$fixed_lengthscales <- lengthscale
	}
	
	## link function
	model <- set_link(model, link)

	## set up response curve
	rcX <- if(response_curve == 'distance') rc_data(model, 'distance') else NA

	## deal with non-rc prediction datasets
	if(!missing(predictX))
	{
		if(!is.list(predictX))
			predictX <- list(predictX)
		if(scale)
		{
			warning("Prediction datasets will be scaled to the same scale as x")
			predictX <- lapply(predictX, model$x_scaling)
		}
		if(is.null(names(predictX)))
			names(predictX) <- 1:length(predictX)
		model$predictX <- lapply(predictX, env_dissim, sitenames = FALSE)
	}
	
	## put prediction datasets together
	if(!is.na(rcX))
	{
		if('predictX' %in% names(model)) {
			model$predictX <- c(rcX, model$predictX)
		} else {
			model$predictX <- rcX
		}
	}

	return(model)	
}

#' Set y transformations for an MBM object assuming a linear increasing mean function
#' @param x an MBM object
#' @param ydat vector of y data points
#' @param link character, link function to use
#' @param eps Constant to add to avoid infinite values for probit
#' @return An mbm object
#' @keywords internal
set_ytrans <- function(x, ydat, link, eps = 0.001)
{
	if(link != 'probit') {
		stop('mean function is only supported for probit or identity links')
	} else if(min(ydat) < 0 | max(ydat) > 1)
		stop('probit data must be on [0,1]')
		
	if(min(ydat) == 0 & max(ydat) == 1)
	{
		# use the smithson transform
		forward <- function(p) qnorm( (p * (length(p) - 1) + 0.5)/length(p))
		back <- function(q) (pnorm(q) * length(q) - 0.5)/(length(q) - 1)
	} else
	{
		# decide on constant to add depending on whether there are 0s or 1s
		eps <- if(min(ydat) == 0) eps else if(max(ydat == 1)) -eps else 0
		forward <- function(p) qnorm(p + eps)
		back <- function(q) pnorm(q) - eps
	}
	x$y_transform <- forward
	x$y_rev_transform <- back
	return(x)
}

#' Add \code{link} and \code{rev_link} closures to mbm model
#' 
#' If a mean function is used, the link will be set to identity, and y_transform and y_untransform
#' methods will also be added.
#' @param x an mbm object
#' @param link character; which link function to use
#' @return \code{x} x with link and rev_link functions added
#' @keywords internal
set_link <- function(x, link = c('identity', 'probit', 'log'))
{
	if(link == 'identity'){
		fun <- unfun <- function(x) x
	} else if(link == 'probit') {
		fun <- qnorm
		unfun <- pnorm
	} else if(link == 'log') {
		fun <- log
		unfun <- exp
	} else 
		stop("unknown link ", link)
	x$link <- fun
	x$rev_link <- unfun
	attr(x, "link_name") <- link
	return(x)
}

