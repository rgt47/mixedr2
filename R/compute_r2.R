#' Fit a linear mixed model
#'
#' Fits an LMM via [lme4::lmer()] and returns the model object
#' along with convergence diagnostics.
#'
#' @param data Data frame with y, x1, x2, ..., cluster_id
#' @param re_structure One of 'intercept' or 'slope'
#' @param n_fixed Number of fixed-effect predictors
#' @return Named list with model (lmerMod or NULL), converged
#'   (logical), singular (logical), warning_messages (character)
#' @importFrom lme4 lmer lmerControl isSingular
#' @export
fit_lmm <- function(data,
                    re_structure = c("intercept", "slope"),
                    n_fixed = 2) {
  re_structure <- match.arg(re_structure)

  fixed_terms <- paste0("x", seq_len(n_fixed))
  fixed_formula <- paste("y ~", paste(fixed_terms, collapse = " + "))

  if (re_structure == "intercept") {
    formula_str <- paste(fixed_formula, "+ (1 | cluster_id)")
  } else {
    formula_str <- paste(
      fixed_formula, "+ (1 + x1 | cluster_id)"
    )
  }

  fm <- as.formula(formula_str)
  warn_msgs <- character(0)

  model <- tryCatch(
    withCallingHandlers(
      lme4::lmer(
        fm,
        data = data,
        control = lme4::lmerControl(
          optimizer = "bobyqa",
          optCtrl = list(maxfun = 1e5)
        )
      ),
      warning = function(w) {
        warn_msgs <<- c(warn_msgs, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      warn_msgs <<- c(warn_msgs, conditionMessage(e))
      NULL
    }
  )

  converged <- !is.null(model)
  singular <- FALSE
  if (converged) {
    singular <- lme4::isSingular(model)
  }

  list(
    model = model,
    converged = converged,
    singular = singular,
    warning_messages = warn_msgs
  )
}


#' Extract R-squared via Nakagawa-Schielzeth method
#'
#' Wraps [MuMIn::r.squaredGLMM()] with the default (log-normal)
#' method corresponding to Nakagawa & Schielzeth (2013).
#'
#' @param model A fitted lmerMod object
#' @return Named numeric vector with R2m and R2c, or c(NA, NA)
#' @importFrom MuMIn r.squaredGLMM
#' @export
extract_r2_nakagawa <- function(model) {
  tryCatch({
    r2 <- MuMIn::r.squaredGLMM(model)
    c(R2m = unname(r2[1, "R2m"]), R2c = unname(r2[1, "R2c"]))
  }, error = function(e) {
    c(R2m = NA_real_, R2c = NA_real_)
  })
}


#' Extract R-squared via Johnson (2014) trigamma method
#'
#' Wraps [MuMIn::r.squaredGLMM()] with method='trigamma'
#' corresponding to Johnson (2014).
#'
#' @param model A fitted lmerMod object
#' @return Named numeric vector with R2m and R2c, or c(NA, NA)
#' @importFrom MuMIn r.squaredGLMM
#' @export
extract_r2_johnson <- function(model) {
  tryCatch({
    r2 <- MuMIn::r.squaredGLMM(model, method = "trigamma")
    c(R2m = unname(r2[1, "R2m"]), R2c = unname(r2[1, "R2c"]))
  }, error = function(e) {
    c(R2m = NA_real_, R2c = NA_real_)
  })
}


#' Compute all R-squared methods for a fitted model
#'
#' Calls both Nakagawa-Schielzeth and Johnson extractors and
#' returns a single-row tibble.
#'
#' @param model A fitted lmerMod object
#' @return A tibble with columns: nak_r2m, nak_r2c, joh_r2m,
#'   joh_r2c
#' @importFrom tibble tibble
#' @export
compute_all_r2 <- function(model) {
  nak <- extract_r2_nakagawa(model)
  joh <- extract_r2_johnson(model)

  tibble::tibble(
    nak_r2m = nak[["R2m"]],
    nak_r2c = nak[["R2c"]],
    joh_r2m = joh[["R2m"]],
    joh_r2c = joh[["R2c"]]
  )
}
