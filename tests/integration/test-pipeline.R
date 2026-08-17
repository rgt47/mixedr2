library(tinytest)
library(mixedr2)

# End-to-end pipeline test: scenario grid -> replicate simulation ->
# summary. Exercises the same driver-to-report path used by
# analysis/scripts/simulation.R, at a reduced scale (2 scenarios,
# 30 reps each) so it runs in seconds rather than minutes. Added in
# remediation of pub_review_whitepaper_2026-08-16.md, Minor issue 4 /
# checklist item (b): tests/integration/ was previously an empty
# directory despite being documented in CLAUDE.md.

grid <- create_scenario_grid(
  n_sim = 30,
  clusters = 20,
  cluster_sizes = 10,
  iccs = c(0.10, 0.40),
  r2ms = 0.20,
  re_structures = "intercept",
  master_seed = 999
)

expect_equal(
  nrow(grid), 60,
  info = "grid has 2 scenarios x 30 reps = 60 rows"
)

results <- generate_simulated_results(
  grid, use_parallel = FALSE, verbose = FALSE
)

expect_equal(
  nrow(results), 60,
  info = "one replicate result row per grid row"
)
expect_true(
  all(results$converged),
  info = "all replicates converge for this well-identified design"
)
expect_false(
  anyNA(results$nak_r2m),
  info = "no silently-dropped NAs in Nakagawa-Schielzeth marginal R2"
)
expect_false(
  anyNA(results$joh_r2m),
  info = "no silently-dropped NAs in Johnson marginal R2"
)

summary_table <- summarize_all_scenarios(results)

expect_equal(
  nrow(summary_table), 2,
  info = "one summary row per scenario"
)
expect_true(
  all(c(
    "nak_m_bias", "joh_m_bias", "nak_m_mse", "joh_m_mse",
    "mono_nak", "mono_joh", "true_r2m", "true_r2c"
  ) %in% names(summary_table)),
  info = "summary table carries the performance columns the report reads"
)
expect_true(
  all(summary_table$mono_nak >= 0 & summary_table$mono_nak <= 1),
  info = "monotonicity rate is a proportion"
)
expect_true(
  all(abs(summary_table$nak_m_bias) < 0.15),
  info = "marginal R2 bias is small at n_sim = 30 for a well-identified design"
)
expect_equal(
  summary_table$true_r2m, rep(0.20, 2),
  tolerance = 1e-8,
  info = "true marginal R2 matches the analytic target for both ICC levels"
)
