# Cross-check of performance::r2_nakagawa() against the package's
# Johnson estimator, on the first 20 replicates of five scenarios.
# Source of the 84 / 16 / 0.046 figures in the manuscript section
# 'The performance Package Implementation'.
#
# Usage (from project root):
#   Rscript analysis/scripts/check_performance_agreement.R
#
# Requires the `performance` package (Suggests). Run on 2026-11-17
# with performance 0.19.0, lme4 2.0-1.

library(mixedr2)

RNGkind("L'Ecuyer-CMRG")
grid <- create_scenario_grid(n_sim = 500)
scenario_ids <- c(1, 8, 17, 24, 32)

out <- purrr::map_dfr(scenario_ids, function(sid) {
  g <- grid[grid$scenario_id == sid, ][1:20, ]
  p <- solve_dgp_params(
    g$target_r2m[1], g$icc[1], re_structure = g$re_structure[1]
  )
  purrr::map_dfr(g$seed, function(s) {
    d <- generate_lmm_data(g$n_clusters[1], g$cluster_size[1], p, s)
    f <- fit_lmm(d, g$re_structure[1])
    pf <- suppressWarnings(suppressMessages(
      performance::r2_nakagawa(f$model)
    ))
    j <- extract_r2_johnson(f$model)
    tibble::tibble(
      scenario_id = sid,
      singular = f$singular,
      diff_m = unname(pf$R2_marginal) - j[['R2m']],
      diff_c = unname(pf$R2_conditional) - j[['R2c']]
    )
  })
})

message('performance ', as.character(packageVersion('performance')))
out |>
  dplyr::group_by(singular) |>
  dplyr::summarise(
    n = dplyr::n(),
    max_abs_diff_m = max(abs(diff_m), na.rm = TRUE),
    n_missing_r2c = sum(is.na(diff_c)),
    max_abs_diff_c = suppressWarnings(max(abs(diff_c), na.rm = TRUE))
  ) |>
  print()
