#' Solve DGP parameters from target R-squared and ICC
#'
#' Given target marginal R-squared and ICC, analytically solves
#' for the variance components (beta coefficients, random effect
#' variances, residual variance) of a linear mixed model.
#'
#' The model is:
#' y_ij = beta_0 + beta_1*x1_ij + ... + b_0i + [b_1i*x1_ij] + eps_ij
#'
#' Variance decomposition (intercept-only random effects):
#'
#' - Var(fixed) = sum(beta_k^2) for standardized predictors
#' - Var(random) = tau0^2
#' - Var(residual) = sigma^2
#' - Var(Y) = Var(fixed) + tau0^2 + sigma^2
#'
#' With random slope on x1:
#'
#' - Var(random) = tau0^2 + tau1^2 * Var(x1) = tau0^2 + tau1^2
#'
#' Targets:
#'
#' - R2_marginal = Var(fixed) / Var(Y) = target_r2m
#' - ICC = tau0^2 / (tau0^2 + sigma^2) = target_icc
#'
#' Fix sigma^2 = 1, solve for tau0^2 and beta.
#'
#' @param target_r2m Target marginal R-squared (0, 1)
#' @param target_icc Target ICC (0, 1)
#' @param n_fixed Number of fixed-effect predictors
#' @param re_structure One of 'intercept' or 'slope'
#' @param sigma2 Residual variance (default 1)
#' @return Named list with beta (vector), tau0, tau1, sigma,
#'   true_r2m, true_r2c, true_icc
#' @export
solve_dgp_params <- function(target_r2m,
                             target_icc,
                             n_fixed = 2,
                             re_structure = c("intercept", "slope"),
                             sigma2 = 1) {
  re_structure <- match.arg(re_structure)
  stopifnot(
    target_r2m > 0, target_r2m < 1,
    target_icc > 0, target_icc < 1,
    n_fixed >= 1,
    sigma2 > 0
  )

  sigma <- sqrt(sigma2)
  tau0_sq <- sigma2 * target_icc / (1 - target_icc)
  tau0 <- sqrt(tau0_sq)

  if (re_structure == "intercept") {
    tau1 <- 0
    var_random <- tau0_sq
  } else {
    tau1 <- tau0 * 0.5
    var_random <- tau0_sq + tau1^2
  }

  var_residual_plus_random <- sigma2 + var_random
  var_fixed <- target_r2m * var_residual_plus_random / (1 - target_r2m)
  beta_k <- sqrt(var_fixed / n_fixed)
  beta <- rep(beta_k, n_fixed)

  var_total <- var_fixed + var_random + sigma2
  true_r2m <- var_fixed / var_total
  true_r2c <- (var_fixed + var_random) / var_total
  true_icc_check <- tau0_sq / (tau0_sq + sigma2)

  list(
    beta = beta,
    tau0 = tau0,
    tau1 = tau1,
    sigma = sigma,
    var_fixed = var_fixed,
    var_random = var_random,
    var_total = var_total,
    true_r2m = true_r2m,
    true_r2c = true_r2c,
    true_icc = true_icc_check
  )
}


#' Compute true marginal R-squared from parameters
#'
#' @param beta Vector of fixed-effect coefficients
#' @param tau0 Random intercept SD
#' @param tau1 Random slope SD (0 for intercept-only)
#' @param sigma Residual SD
#' @return Scalar true marginal R-squared
#' @export
true_r2_marginal <- function(beta, tau0, tau1 = 0, sigma) {
  var_fixed <- sum(beta^2)
  var_random <- tau0^2 + tau1^2
  var_total <- var_fixed + var_random + sigma^2
  var_fixed / var_total
}


#' Compute true conditional R-squared from parameters
#'
#' @param beta Vector of fixed-effect coefficients
#' @param tau0 Random intercept SD
#' @param tau1 Random slope SD (0 for intercept-only)
#' @param sigma Residual SD
#' @return Scalar true conditional R-squared
#' @export
true_r2_conditional <- function(beta, tau0, tau1 = 0, sigma) {
  var_fixed <- sum(beta^2)
  var_random <- tau0^2 + tau1^2
  var_total <- var_fixed + var_random + sigma^2
  (var_fixed + var_random) / var_total
}
