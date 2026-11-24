#' Run a single simulation replicate
#'
#' Generates data and fits up to four models to the same data set:
#'
#' - full: true predictors x1, x2 and the generating random-effects
#'   structure (accuracy and precision aims);
#' - reduced: x1 only (monotonicity under adding a true predictor);
#' - null-augmented: x1, x2 and a null predictor x3 with true
#'   coefficient zero (monotonicity under adding a null predictor);
#' - misspecified: x1, x2 with a random intercept only, fitted in
#'   random-slope scenarios (robustness to an omitted slope).
#'
#' @param params List from [solve_dgp_params()]
#' @param n_clusters Number of clusters
#' @param cluster_size Observations per cluster
#' @param re_structure 'intercept' or 'slope'
#' @param n_fixed Number of fixed-effect predictors
#' @param seed Integer seed
#' @param mumin Logical; compute the MuMIn cross-check on the full
#'   model
#' @return A single-row tibble with R-squared estimates and
#'   diagnostics
#' @importFrom tibble tibble
#' @export
run_single_replicate <- function(params,
                                 n_clusters,
                                 cluster_size,
                                 re_structure,
                                 n_fixed = 2,
                                 seed,
                                 mumin = TRUE) {
  dat <- generate_lmm_data(
    n_clusters = n_clusters,
    cluster_size = cluster_size,
    params = params,
    seed = seed,
    n_null = 1
  )

  na_r2 <- function(prefix) {
    out <- as.list(rep(NA_real_, 4))
    names(out) <- paste0(
      prefix, c('nak_r2m', 'nak_r2c', 'joh_r2m', 'joh_r2c')
    )
    tibble::as_tibble(out)
  }

  r2_or_na <- function(fit, prefix) {
    if (!fit$converged) return(na_r2(prefix))
    r2 <- compute_all_r2(fit$model, mumin = FALSE)[
      c('nak_r2m', 'nak_r2c', 'joh_r2m', 'joh_r2c')
    ]
    names(r2) <- paste0(prefix, names(r2))
    r2
  }

  fit_full <- fit_lmm(
    dat, re_structure = re_structure, n_fixed = n_fixed
  )

  if (!fit_full$converged) {
    return(tibble::tibble(
      nak_r2m = NA_real_, nak_r2c = NA_real_,
      joh_r2m = NA_real_, joh_r2c = NA_real_,
      adj_r2m = NA_real_,
      converged = FALSE, conv_warning = NA, singular = NA
    ))
  }

  r2_full <- compute_all_r2(fit_full$model, mumin = mumin)

  fit_red <- fit_lmm(
    dat, re_structure = re_structure, n_fixed = n_fixed - 1
  )
  fit_nul <- fit_lmm(
    dat, re_structure = re_structure, n_fixed = n_fixed + 1
  )

  if (re_structure == 'slope') {
    fit_mis <- fit_lmm(
      dat, re_structure = 'intercept', n_fixed = n_fixed
    )
    r2_mis <- r2_or_na(fit_mis, 'mis_')[
      c('mis_joh_r2m', 'mis_joh_r2c')
    ]
    names(r2_mis) <- c('mis_r2m', 'mis_r2c')
    r2_mis$mis_singular <- if (fit_mis$converged) {
      fit_mis$singular
    } else {
      NA
    }
  } else {
    r2_mis <- tibble::tibble(
      mis_r2m = NA_real_, mis_r2c = NA_real_, mis_singular = NA
    )
  }

  dplyr::bind_cols(
    r2_full,
    r2_or_na(fit_red, 'red_'),
    r2_or_na(fit_nul, 'nul_'),
    r2_mis,
    tibble::tibble(
      converged = fit_full$converged,
      conv_warning = fit_full$conv_warning,
      singular = fit_full$singular
    )
  )
}


#' Run all replicates for one scenario
#'
#' @param scenario_row A single row from the scenario grid. An
#'   optional `tau_ratio` column sets tau1 / tau0 in random-slope
#'   scenarios; when absent the default of [solve_dgp_params()]
#'   (0.5) is used.
#' @param n_sim Number of replications
#' @param seeds Vector of integer seeds (length n_sim)
#' @param use_parallel Logical, whether to use furrr
#' @return A tibble with n_sim rows of R-squared estimates
#' @importFrom purrr map_dfr
#' @export
run_scenario <- function(scenario_row,
                         n_sim,
                         seeds,
                         use_parallel = TRUE) {
  tau_ratio <- if ('tau_ratio' %in% names(scenario_row)) {
    scenario_row$tau_ratio
  } else {
    0.5
  }
  params <- solve_dgp_params(
    target_r2m = scenario_row$target_r2m,
    target_icc = scenario_row$icc,
    n_fixed = 2,
    re_structure = scenario_row$re_structure,
    tau_ratio = tau_ratio
  )

  # Workers start with R's default RNG kind. Without this, the same
  # per-replicate seed gives different data under parallel and
  # sequential execution (found 2026-11-17).
  rng_kind <- RNGkind()

  run_one <- function(seed) {
    RNGkind(rng_kind[1], rng_kind[2], rng_kind[3])
    run_single_replicate(
      params = params,
      n_clusters = scenario_row$n_clusters,
      cluster_size = scenario_row$cluster_size,
      re_structure = scenario_row$re_structure,
      n_fixed = 2,
      seed = seed
    )
  }

  if (use_parallel) {
    results <- furrr::future_map_dfr(
      seeds, run_one,
      .options = furrr::furrr_options(
        seed = NULL,
        packages = "mixedr2"
      )
    )
  } else {
    results <- purrr::map_dfr(seeds, run_one)
  }

  results$true_r2m <- params$true_r2m
  results$true_r2c <- params$true_r2c
  results
}


#' Run full simulation across all scenarios
#'
#' Top-level orchestration function. Iterates over scenarios
#' (sequentially) and parallelizes within each scenario.
#'
#' @param grid Scenario grid from [create_scenario_grid()]
#' @param use_parallel Use furrr for within-scenario parallelism
#' @param verbose Print progress messages
#' @return A tibble with all replicate results, including
#'   scenario metadata
#' @importFrom dplyr bind_rows
#' @export
generate_simulated_results <- function(grid,
                                       use_parallel = TRUE,
                                       verbose = TRUE) {
  scenarios <- unique(grid$scenario_id)
  all_results <- vector("list", length(scenarios))

  for (i in seq_along(scenarios)) {
    sid <- scenarios[i]
    scenario_grid <- grid[grid$scenario_id == sid, ]
    scenario_row <- scenario_grid[1, ]
    n_sim <- nrow(scenario_grid)
    seeds <- scenario_grid$seed

    if (verbose) {
      message(
        sprintf(
          "[%s] Scenario %d/%d: J=%d, n=%d, ICC=%.2f, R2m=%.2f, RE=%s",
          format(Sys.time(), "%H:%M:%S"),
          i, length(scenarios),
          scenario_row$n_clusters,
          scenario_row$cluster_size,
          scenario_row$icc,
          scenario_row$target_r2m,
          scenario_row$re_structure
        )
      )
    }

    results <- run_scenario(
      scenario_row = scenario_row,
      n_sim = n_sim,
      seeds = seeds,
      use_parallel = use_parallel
    )

    results$scenario_id <- sid
    results$n_clusters <- scenario_row$n_clusters
    results$cluster_size <- scenario_row$cluster_size
    results$icc <- scenario_row$icc
    results$target_r2m <- scenario_row$target_r2m
    results$re_structure <- scenario_row$re_structure
    results$rep_id <- seq_len(n_sim)
    # Storing the seed makes each replicate regenerable directly
    # from the results file (Morris et al. 2019, section 4.1).
    results$seed <- seeds
    if ('tau_ratio' %in% names(scenario_row)) {
      results$tau_ratio <- scenario_row$tau_ratio
    }

    all_results[[i]] <- results
  }

  dplyr::bind_rows(all_results)
}
