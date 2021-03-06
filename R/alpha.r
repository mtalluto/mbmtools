### set of simple functions for computing simpler alpha diversity metrics


#' @name alpha_diversity
#' @aliases richness
#' @aliases simpson
#' @aliases shannon
#' @title Compute alpha diversity metrics
#' 
#' Note that the Simpson index here is the probability that two individuals randomly drawn will
#' be of the same taxon, and thus gets larger as diveristy *decreases*.
#' @rdname alpha_diversity
#' @param x A matrix with rows as sites and species as columns. Values are abundances or 
#' 		presence/absence
#' @return A vector of diversity values
#' @export
richness <- function(x) {
	if(any(x < 0)) stop("Values in x must be positive")
	x[x > 0] <- 1
	x[x != 1] <- 0
	rowSums(x)
}

#' @rdname alpha_diversity
#' @param proportion Logical. If true, abundances in x are considered proportional abundances. 
#' 		If false, x will be transformed to proportional abundance
#' @export
simpson <- function(x, proportion=TRUE) {
	if(any(x < 0) | (proportion & any(rowSums(x) > 1))) stop("Abundances must be >= 0 and must be <= 1 if proportion=TRUE")
	if(! proportion) {
		N <- matrix(rowSums(x), nrow=nrow(x), ncol=ncol(x))
		x <- x/N
	}
	apply(x, 1, function(xx) sum(xx^2))
}

#' @rdname alpha_diversity
#' @export
shannon <- function(x) {
	if(!all(.fp_equal(rowSums(x), 1))) {
		warning(paste("Data for shannon diversity are not proportions;",
		              "data will be rescaled to proportional cover"))
		x <- t(apply(x, 1, function(xx) xx/sum(xx)))
	}
	apply(x, 1, function(xx) {
		xx <- xx[xx!= 0]
		-sum(xx * log(xx))	
	})
}

.fp_equal <- function(x,y,tol=1e-9) {
	abs(x - y) <= tol
}
