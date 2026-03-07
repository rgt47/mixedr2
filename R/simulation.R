#' Run a single simulation replicate
#'
#' Generates data, fits the full model (and a reduced model for
#' monotonicity testing), and extracts R-squared from all methods.
#'
#' @param params List from [solve_dgp_params()]
#' @param n_clusters Number of clusters
#' @param cluster_size Observations per cluster
#' @param re_structure 'intercept' or 'slope'
#' @param n_fixed Number of fixed-effect predictors
#' @param seed Integer seed
#' @return A single-row tibble with R-squared estimates and
#'   diagnostics
#' @importFrom tibble tibble
#' @export
run_single_replicate <- function(params,
                                 n_clusters,
                                 cluster_size,
                                 re_structure,
                                 n_fixed = 2,
                                 seed) {
  dat <- generate_lmm_data(
    n_clusters = n_clusters,
    cluster_size = cluster_size,
    params = params,
    seed = seed
  )

  fit_full <- fit_lmm(
    dat,
    re_structure = re_structure,
    n_fixed = n_fixed
  )

  if (!fit_full$converged) {
    return(tibble::tibble(
      nak_r2m = NA_real_, nak_r2c = NA_real_,
      joh_r2m = NA_real_, joh_r2c = NA_real_,
      red_nak_r2m = NA_real_, red_joh_r2m = NA_real_,
      converged = FALSE, singular = FALSE
    ))
  }

  r2_full <- compute_all_r2(fit_full$model)

  fit_red <- fit_lmm(
    dat,
    re_structure = re_structure,
    n_fixed = 1
  )

  if (fit_red$converged) {
    r2_red <- compute_all_r2(fit_red$model)
    red_nak_r2m <- r2_red$nak_r2m
    red_joh_r2m <- r2_red$joh_r2m
  } else {
    red_nak_r2m <- NA_real_
    red_joh_r2m <- NA_real_
  }

  tibble::tibble(
    nak_r2m = r2_full$nak_r2m,
    nak_r2c = r2_full$nak_r2c,
    joh_r2m = r2_full$joh_r2m,
    joh_r2c = r2_full$joh_r2c,
    red_nak_r2m = red_nak_r2m,
    red_joh_r2m = red_joh_r2m,
    converged = fit_full$converged,
    singular = fit_full$singular
  )
}


#' Run all replicates for one scenario
#'
#' @param scenario_row A single row from the scenario grid
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
  params <- solve_dgp_params(
    target_r2m = scenario_row$target_r2m,
    target_icc = scenario_row$icc,
    n_fixed = 2,
    re_structure = scenario_row$re_structure
  )

  run_one <- function(seed) {
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

    all_results[[i]] <- results
  }

  dplyr::bind_rows(all_results)
}
