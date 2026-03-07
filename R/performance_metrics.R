#' Calculate bias
#'
#' @param estimates Numeric vector of estimates
#' @param truth Scalar true value
#' @return Scalar bias (mean estimate - truth)
#' @export
calculate_bias <- function(estimates, truth) {
  mean(estimates, na.rm = TRUE) - truth
}


#' Calculate relative bias
#'
#' @param estimates Numeric vector of estimates
#' @param truth Scalar true value
#' @return Scalar relative bias (bias / truth)
#' @export
calculate_relative_bias <- function(estimates, truth) {
  if (abs(truth) < 1e-10) return(NA_real_)
  calculate_bias(estimates, truth) / truth
}


#' Calculate mean squared error
#'
#' @param estimates Numeric vector of estimates
#' @param truth Scalar true value
#' @return Scalar MSE
#' @export
calculate_mse <- function(estimates, truth) {
  mean((estimates - truth)^2, na.rm = TRUE)
}


#' Calculate empirical variance of estimates
#'
#' @param estimates Numeric vector of estimates
#' @return Scalar variance
#' @export
calculate_variance <- function(estimates) {
  stats::var(estimates, na.rm = TRUE)
}


#' Calculate monotonicity rate
#'
#' Proportion of replicates where R2(full) >= R2(reduced).
#'
#' @param r2_full Numeric vector of R2 from full model
#' @param r2_reduced Numeric vector of R2 from reduced model
#' @return Scalar proportion in [0, 1]
#' @export
calculate_monotonicity_rate <- function(r2_full, r2_reduced) {
  valid <- !is.na(r2_full) & !is.na(r2_reduced)
  if (sum(valid) == 0) return(NA_real_)
  mean(r2_full[valid] >= r2_reduced[valid])
}


#' Calculate boundary violation rate
#'
#' Proportion of estimates outside [0, 1].
#'
#' @param estimates Numeric vector of R2 estimates
#' @return Scalar proportion
#' @export
calculate_boundary_violations <- function(estimates) {
  valid <- !is.na(estimates)
  if (sum(valid) == 0) return(NA_real_)
  mean(estimates[valid] < 0 | estimates[valid] > 1)
}


#' Monte Carlo SE for bias (Morris et al. 2019)
#'
#' MCSE(bias) = sqrt(Var(estimates) / n_sim)
#'
#' @param estimates Numeric vector of estimates
#' @return Scalar MCSE
#' @export
calculate_mcse_bias <- function(estimates) {
  n <- sum(!is.na(estimates))
  if (n < 2) return(NA_real_)
  sqrt(stats::var(estimates, na.rm = TRUE) / n)
}


#' Monte Carlo SE for MSE (Morris et al. 2019)
#'
#' @param estimates Numeric vector of estimates
#' @param truth Scalar true value
#' @return Scalar MCSE
#' @export
calculate_mcse_mse <- function(estimates, truth) {
  valid <- estimates[!is.na(estimates)]
  n <- length(valid)
  if (n < 2) return(NA_real_)
  sq_errors <- (valid - truth)^2
  sqrt(stats::var(sq_errors) / n)
}


#' Monte Carlo SE for a proportion (Morris et al. 2019)
#'
#' @param p Estimated proportion
#' @param n_sim Number of simulations
#' @return Scalar MCSE
#' @export
calculate_mcse_proportion <- function(p, n_sim) {
  if (n_sim < 1 || is.na(p)) return(NA_real_)
  sqrt(p * (1 - p) / n_sim)
}


#' Summarize simulation performance for one scenario
#'
#' Computes all performance measures for a single scenario's
#' replicate results.
#'
#' @param results Tibble of replicate results (from
#'   [run_scenario()])
#' @param true_r2m True marginal R-squared
#' @param true_r2c True conditional R-squared
#' @return A single-row tibble with all performance measures
#' @importFrom tibble tibble
#' @export
summarize_performance <- function(results, true_r2m, true_r2c) {
  n_sim <- nrow(results)
  n_converged <- sum(results$converged, na.rm = TRUE)
  n_singular <- sum(results$singular, na.rm = TRUE)

  make_metrics <- function(estimates, truth, prefix) {
    bias <- calculate_bias(estimates, truth)
    stats::setNames(
      c(
        bias,
        calculate_relative_bias(estimates, truth),
        calculate_variance(estimates),
        calculate_mse(estimates, truth),
        calculate_mcse_bias(estimates),
        calculate_mcse_mse(estimates, truth),
        calculate_boundary_violations(estimates)
      ),
      paste0(
        prefix, "_",
        c("bias", "rel_bias", "var", "mse",
          "mcse_bias", "mcse_mse", "boundary_viol")
      )
    )
  }

  nak_m <- make_metrics(results$nak_r2m, true_r2m, "nak_m")
  nak_c <- make_metrics(results$nak_r2c, true_r2c, "nak_c")
  joh_m <- make_metrics(results$joh_r2m, true_r2m, "joh_m")
  joh_c <- make_metrics(results$joh_r2c, true_r2c, "joh_c")

  mono_nak <- calculate_monotonicity_rate(
    results$nak_r2m, results$red_nak_r2m
  )
  mono_joh <- calculate_monotonicity_rate(
    results$joh_r2m, results$red_joh_r2m
  )

  as_tibble_row <- function(x) {
    tibble::as_tibble(as.list(x))
  }

  dplyr::bind_cols(
    tibble::tibble(
      n_sim = n_sim,
      n_converged = n_converged,
      n_singular = n_singular,
      convergence_rate = n_converged / n_sim,
      singular_rate = n_singular / n_sim,
      true_r2m = true_r2m,
      true_r2c = true_r2c
    ),
    as_tibble_row(nak_m),
    as_tibble_row(nak_c),
    as_tibble_row(joh_m),
    as_tibble_row(joh_c),
    tibble::tibble(
      mono_nak = mono_nak,
      mono_joh = mono_joh,
      mcse_mono_nak = calculate_mcse_proportion(mono_nak, n_sim),
      mcse_mono_joh = calculate_mcse_proportion(mono_joh, n_sim)
    )
  )
}


#' Summarize all scenarios
#'
#' Applies [summarize_performance()] to each scenario in the
#' full results tibble.
#'
#' @param all_results Full simulation results from
#'   [generate_simulated_results()]
#' @return A tibble with one row per scenario
#' @importFrom dplyr group_by group_split select
#' @importFrom purrr map_dfr
#' @export
summarize_all_scenarios <- function(all_results) {
  scenario_ids <- unique(all_results$scenario_id)

  purrr::map_dfr(scenario_ids, function(sid) {
    sc <- all_results[all_results$scenario_id == sid, ]
    true_r2m <- sc$true_r2m[1]
    true_r2c <- sc$true_r2c[1]

    perf <- summarize_performance(sc, true_r2m, true_r2c)

    dplyr::bind_cols(
      tibble::tibble(
        scenario_id = sid,
        n_clusters = sc$n_clusters[1],
        cluster_size = sc$cluster_size[1],
        icc = sc$icc[1],
        target_r2m = sc$target_r2m[1],
        re_structure = sc$re_structure[1]
      ),
      perf
    )
  })
}
