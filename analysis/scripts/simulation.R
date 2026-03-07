# Top-level simulation driver for plan-short.md
# 32 scenarios x 500 reps = 16,000 fits
# Run time: ~10 min on 8 cores
#
# Usage (from project root inside container):
#   Rscript analysis/scripts/simulation.R
#   Rscript analysis/scripts/simulation.R --pilot   # 10 reps

library(mixedr2)

args <- commandArgs(trailingOnly = TRUE)
pilot <- "--pilot" %in% args

if (pilot) {
  n_sim <- 10
  message("=== PILOT RUN (10 reps) ===")
} else {
  n_sim <- 500
  message("=== FULL RUN (500 reps) ===")
}

grid <- create_scenario_grid(n_sim = n_sim)
message(
  sprintf(
    "%d scenarios x %d reps = %d total fits",
    length(unique(grid$scenario_id)), n_sim, nrow(grid)
  )
)

setup_parallel()
on.exit(teardown_parallel())

t0 <- Sys.time()
results <- generate_simulated_results(
  grid, use_parallel = TRUE, verbose = TRUE
)
elapsed <- difftime(Sys.time(), t0, units = "mins")
message(sprintf("Elapsed: %.1f minutes", as.numeric(elapsed)))

summary_table <- summarize_all_scenarios(results)

out_dir <- "analysis/data/derived_data"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

if (pilot) {
  saveRDS(results, file.path(out_dir, "pilot_results.rds"))
  saveRDS(summary_table, file.path(out_dir, "pilot_summary.rds"))
  message("Saved pilot results to ", out_dir)
} else {
  saveRDS(results, file.path(out_dir, "sim_results.rds"))
  saveRDS(summary_table, file.path(out_dir, "sim_summary.rds"))
  message("Saved full results to ", out_dir)
}

message("\nConvergence summary:")
print(
  summary_table[,
    c("scenario_id", "n_clusters", "cluster_size", "icc",
      "target_r2m", "re_structure", "convergence_rate",
      "singular_rate")
  ],
  n = 32
)
