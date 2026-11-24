#' Fit a linear mixed model
#'
#' Fits an LMM via [lme4::lmer()] and returns the model object
#' along with convergence diagnostics.
#'
#' `converged` is `TRUE` whenever `lmer()` returned a model object
#' without an error. It is therefore not a convergence diagnostic
#' on its own. `conv_warning` flags fits for which `lme4` reported
#' a convergence problem (a gradient, Hessian or eigenvalue check
#' failure), either as a captured warning or in the optimizer
#' information stored on the fit. Such fits are retained.
#'
#' @param data Data frame with y, x1, x2, ..., cluster_id
#' @param re_structure One of 'intercept' or 'slope'
#' @param n_fixed Number of fixed-effect predictors
#' @return Named list with model (lmerMod or NULL), converged
#'   (logical), conv_warning (logical), singular (logical),
#'   warning_messages (character)
#' @importFrom lme4 lmer lmerControl isSingular
#' @export
fit_lmm <- function(data,
                    re_structure = c('intercept', 'slope'),
                    n_fixed = 2) {
  re_structure <- match.arg(re_structure)

  fixed_terms <- paste0('x', seq_len(n_fixed))
  fixed_formula <- paste('y ~', paste(fixed_terms, collapse = ' + '))

  if (re_structure == 'intercept') {
    formula_str <- paste(fixed_formula, '+ (1 | cluster_id)')
  } else {
    formula_str <- paste(
      fixed_formula, '+ (1 + x1 | cluster_id)'
    )
  }

  fm <- stats::as.formula(formula_str)
  warn_msgs <- character(0)

  model <- tryCatch(
    withCallingHandlers(
      lme4::lmer(
        fm,
        data = data,
        control = lme4::lmerControl(
          optimizer = 'bobyqa',
          optCtrl = list(maxfun = 1e5)
        )
      ),
      warning = function(w) {
        warn_msgs <<- c(warn_msgs, conditionMessage(w))
        invokeRestart('muffleWarning')
      }
    ),
    error = function(e) {
      warn_msgs <<- c(warn_msgs, conditionMessage(e))
      NULL
    }
  )

  converged <- !is.null(model)
  singular <- FALSE
  conv_warning <- FALSE
  if (converged) {
    singular <- lme4::isSingular(model)
    opt_msgs <- c(
      model@optinfo$conv$lme4$messages,
      model@optinfo$warnings |> unlist() |> as.character()
    )
    conv_pattern <- 'converge|gradient|Hessian|eigenvalue'
    conv_warning <- any(
      grepl(conv_pattern, c(warn_msgs, opt_msgs), ignore.case = TRUE)
    )
  }

  list(
    model = model,
    converged = converged,
    conv_warning = conv_warning,
    singular = singular,
    warning_messages = warn_msgs
  )
}


#' Variance components used by the R-squared estimators
#'
#' Computes, from one fitted Gaussian LMM, the plug-in variance
#' terms on which every estimator in this package is built.
#'
#' - `var_f`: sample variance of the fixed-effect linear predictor,
#'   \eqn{\widehat{\mathrm{Var}}(X\hat\beta)}.
#' - `var_int`: estimated random-intercept variance
#'   \eqn{\hat\tau_0^2} only. This is the random-effect variance in
#'   the original Nakagawa and Schielzeth (2013) formula, which was
#'   defined for random-intercept models.
#' - `var_joh`: Johnson's (2014) random-effect variance, the mean of
#'   \eqn{\mathrm{diag}(Z \hat\Sigma Z^\top)} over observations. It
#'   includes the random-slope variance and the intercept-slope
#'   covariance. It equals `var_int` for random-intercept models.
#' - `sigma2`: estimated residual variance.
#' - `trace_term`: \eqn{\mathrm{tr}\{\widehat{\mathrm{Var}}(\hat\beta)
#'   S_x\}}, the leading-order upward bias of `var_f`, where
#'   \eqn{S_x} is the sample covariance of the non-intercept
#'   columns of \eqn{X}.
#'
#' @param model A fitted lmerMod object with grouping factor
#'   `cluster_id`
#' @return Named numeric vector with var_f, var_int, var_joh,
#'   sigma2, trace_term
#' @importFrom lme4 getME fixef VarCorr
#' @export
r2_variance_components <- function(model) {
  x <- lme4::getME(model, 'X')
  var_f <- stats::var(as.vector(x %*% lme4::fixef(model)))

  g_hat <- as.matrix(lme4::VarCorr(model)$cluster_id)
  re_names <- colnames(g_hat)
  z <- x[, re_names, drop = FALSE]
  var_joh <- mean(rowSums((z %*% g_hat) * z))
  var_int <- g_hat['(Intercept)', '(Intercept)']

  slope_cols <- setdiff(colnames(x), '(Intercept)')
  v_beta <- as.matrix(stats::vcov(model))[slope_cols, slope_cols,
                                          drop = FALSE]
  s_x <- stats::cov(x[, slope_cols, drop = FALSE])
  trace_term <- sum(diag(v_beta %*% s_x))

  c(
    var_f = var_f,
    var_int = var_int,
    var_joh = var_joh,
    sigma2 = stats::sigma(model)^2,
    trace_term = trace_term
  )
}


#' Marginal and conditional R-squared from variance terms
#'
#' @param var_f Fixed-effect variance
#' @param var_re Random-effect variance
#' @param sigma2 Residual variance
#' @return Named numeric vector with R2m and R2c
#' @keywords internal
r2_from_components <- function(var_f, var_re, sigma2) {
  total <- var_f + var_re + sigma2
  c(R2m = var_f / total, R2c = (var_f + var_re) / total)
}


#' R-squared via the original Nakagawa-Schielzeth (2013) formula
#'
#' Implements the 2013 random-intercept formula explicitly. The
#' random-effect variance is the estimated intercept variance
#' \eqn{\hat\tau_0^2} only. Any random-slope variance is ignored.
#' For random-intercept models this coincides with
#' [extract_r2_johnson()]. For random-slope models it is the
#' estimator an analyst obtains by applying the 2013 formula
#' without Johnson's (2014) extension.
#'
#' @param model A fitted lmerMod object
#' @return Named numeric vector with R2m and R2c, or c(NA, NA)
#' @export
extract_r2_nakagawa <- function(model) {
  tryCatch({
    vc <- r2_variance_components(model)
    r2_from_components(vc[['var_f']], vc[['var_int']], vc[['sigma2']])
  }, error = function(e) {
    c(R2m = NA_real_, R2c = NA_real_)
  })
}


#' R-squared via the Johnson (2014) random-slope extension
#'
#' Implements Johnson's random-effect variance,
#' \eqn{\overline{\mathrm{diag}}(Z \hat\Sigma Z^\top)}, directly
#' from the fitted model. For Gaussian LMMs this agrees with
#' [MuMIn::r.squaredGLMM()] (see [extract_r2_mumin()]), which has
#' applied the Johnson variance term to random-slope fits since
#' the Nakagawa, Johnson and Schielzeth (2017) update.
#'
#' @param model A fitted lmerMod object
#' @return Named numeric vector with R2m and R2c, or c(NA, NA)
#' @export
extract_r2_johnson <- function(model) {
  tryCatch({
    vc <- r2_variance_components(model)
    r2_from_components(vc[['var_f']], vc[['var_joh']], vc[['sigma2']])
  }, error = function(e) {
    c(R2m = NA_real_, R2c = NA_real_)
  })
}


#' Bias-adjusted marginal R-squared
#'
#' Subtracts the leading-order upward bias of the plug-in
#' fixed-effect variance,
#' \eqn{\mathrm{tr}\{\widehat{\mathrm{Var}}(\hat\beta) S_x\}}, from
#' \eqn{\widehat{\mathrm{Var}}(X\hat\beta)}, truncates at zero, and
#' uses the Johnson random-effect variance in the denominator.
#' This is an exploratory comparator. It is not a published
#' estimator.
#'
#' @param model A fitted lmerMod object
#' @return Scalar adjusted marginal R-squared, or NA
#' @export
extract_r2m_adjusted <- function(model) {
  tryCatch({
    vc <- r2_variance_components(model)
    var_f_adj <- max(0, vc[['var_f']] - vc[['trace_term']])
    r2_from_components(
      var_f_adj, vc[['var_joh']], vc[['sigma2']]
    )[['R2m']]
  }, error = function(e) {
    NA_real_
  })
}


#' R-squared from MuMIn, as an implementation cross-check
#'
#' Wraps [MuMIn::r.squaredGLMM()] with its default arguments. For a
#' Gaussian LMM the `method` argument of `r.squaredGLMM()` only
#' selects the observation-level variance approximation used for
#' non-Gaussian families, so it has no effect here. The result is
#' used to check [extract_r2_johnson()] and is not a separate
#' estimator.
#'
#' @param model A fitted lmerMod object
#' @return Named numeric vector with R2m and R2c, or c(NA, NA)
#' @importFrom MuMIn r.squaredGLMM
#' @export
extract_r2_mumin <- function(model) {
  tryCatch({
    r2 <- suppressWarnings(MuMIn::r.squaredGLMM(model))
    c(R2m = unname(r2[1, 'R2m']), R2c = unname(r2[1, 'R2c']))
  }, error = function(e) {
    c(R2m = NA_real_, R2c = NA_real_)
  })
}


#' Compute all R-squared estimators for a fitted model
#'
#' @param model A fitted lmerMod object
#' @param mumin Logical; also compute the MuMIn cross-check
#' @return A single-row tibble with columns nak_r2m, nak_r2c,
#'   joh_r2m, joh_r2c, adj_r2m, and (if `mumin`) mumin_r2m,
#'   mumin_r2c
#' @importFrom tibble tibble
#' @export
compute_all_r2 <- function(model, mumin = TRUE) {
  nak <- extract_r2_nakagawa(model)
  joh <- extract_r2_johnson(model)

  out <- tibble::tibble(
    nak_r2m = nak[['R2m']],
    nak_r2c = nak[['R2c']],
    joh_r2m = joh[['R2m']],
    joh_r2c = joh[['R2c']],
    adj_r2m = extract_r2m_adjusted(model)
  )
  if (mumin) {
    mm <- extract_r2_mumin(model)
    out$mumin_r2m <- mm[['R2m']]
    out$mumin_r2c <- mm[['R2c']]
  }
  out
}
