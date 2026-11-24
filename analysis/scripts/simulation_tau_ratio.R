# Sensitivity of the random-slope results to tau1 / tau0.
#
# The main simulation (analysis/scripts/simulation.R) fixes
# tau1 = 0.5 * tau0. This driver reruns only the 16 random-slope
# scenarios (IDs 17 to 32) at other ratios. It reuses the main
# grid's scenario IDs and per-replicate seeds, so every replicate is
# paired with the same replicate of the main run; only tau1 changes.
# Results are written to separate files and do not touch
# sim_results.rds.
#
# Usage (from project root):
#   Rscript analysis/scripts/simulation_tau_ratio.R            # 0.25, 1
#   Rscript analysis/scripts/simulation_tau_ratio.R --ratio=1
#   Rscript analysis/scripts/simulation_tau_ratio.R --reps=20  # trial
#   Rscript analysis/scripts/simulation_tau_ratio.R --parallel
#
# Output: analysis/data/derived_data/sim_results_tau_<ratio>.rds and
# sim_summary_tau_<ratio>.rds. Trial runs (--reps < 500) time and
# validate the run but save nothing.

pkgload::load_all('.', quiet = TRUE)

RNGkind("L'Ecuyer-CMRG")

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name, default) {
  hit <- grep(paste0('^--', name, '='), args, value = TRUE)
  if (length(hit) == 0) return(default)
  as.numeric(sub(paste0('^--', name, '='), '', hit[1]))
}
ratios <- arg_value('ratio', c(0.25, 1))
reps <- arg_value('reps', 500)
use_parallel <- '--parallel' %in% args
stopifnot(reps >= 1, reps <= 500, all(ratios > 0))

if (use_parallel) {
  setup_parallel()
  on.exit(teardown_parallel())
}

out_dir <- 'analysis/data/derived_data'

for (r in ratios) {
  grid <- create_scenario_grid(n_sim = 500, tau_ratio = r)
  grid <- grid[grid$re_structure == 'slope' & grid$rep_id <= reps, ]
  message(sprintf(
    'tau1/tau0 = %.2f: %d scenarios x %d reps',
    r, length(unique(grid$scenario_id)), reps
  ))
  t0 <- Sys.time()
  results <- generate_simulated_results(
    grid, use_parallel = use_parallel, verbose = TRUE
  )
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = 'mins'))
  message(sprintf('Elapsed: %.2f minutes', elapsed))
  stopifnot(
    nrow(results) == nrow(grid),
    identical(results$seed, grid$seed),
    all(results$tau_ratio == r)
  )
  summary_table <- summarize_all_scenarios(results)
  if (reps < 500) {
    message('Trial run (--reps < 500): results not saved')
    next
  }
  tag <- paste0('tau_', format(r))
  saveRDS(results,
          file.path(out_dir, paste0('sim_results_', tag, '.rds')))
  saveRDS(summary_table,
          file.path(out_dir, paste0('sim_summary_', tag, '.rds')))
}
