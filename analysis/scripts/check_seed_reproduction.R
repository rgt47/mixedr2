# Reconstruction check for the stored simulation results.
#
# Each replicate's RNG state is fixed by its integer seed (pre-drawn
# from master seed 20260306 by create_scenario_grid() under
# L'Ecuyer-CMRG) and set by set.seed() inside generate_lmm_data().
# This script regenerates the first and last replicate of every
# scenario from those seeds alone, sequentially, and compares every
# stored R-squared column with the regenerated value. It is the
# source of the reconstruction figures in the ADEMP appendix of
# analysis/report/report.Rmd.
#
# Usage (from project root):
#   Rscript analysis/scripts/check_seed_reproduction.R
#
# Output: analysis/data/derived_data/seed_reproduction_check.csv

pkgload::load_all('.', quiet = TRUE)

RNGkind("L'Ecuyer-CMRG")
grid <- create_scenario_grid(n_sim = 500)
stored <- readRDS('analysis/data/derived_data/sim_results.rds')

stopifnot(
  nrow(stored) == nrow(grid),
  identical(as.integer(stored$scenario_id), as.integer(grid$scenario_id)),
  identical(as.integer(stored$rep_id), as.integer(grid$rep_id))
)

r2_cols <- grep('r2[mc]$', names(stored), value = TRUE)
r2_cols <- setdiff(r2_cols, c('true_r2m', 'true_r2c', 'target_r2m'))

rows <- which(grid$rep_id %in% c(1L, 500L))

t0 <- Sys.time()
regen <- purrr::map_dfr(rows, function(i) {
  g <- grid[i, ]
  out <- run_scenario(g, 1, seeds = g$seed, use_parallel = FALSE)
  out$row <- i
  out
})
elapsed_sec <- as.numeric(difftime(Sys.time(), t0, units = 'secs'))

max_abs_diff <- function(col) {
  a <- stored[[col]][rows]
  b <- regen[[col]]
  stopifnot(identical(is.na(a), is.na(b)))
  if (all(is.na(a))) return(NA_real_)
  max(abs(a - b), na.rm = TRUE)
}

check <- tibble::tibble(
  column = r2_cols,
  n_replicates = length(rows),
  n_scenarios = length(unique(grid$scenario_id[rows])),
  max_abs_diff = purrr::map_dbl(r2_cols, max_abs_diff),
  elapsed_sec = elapsed_sec,
  run_date = format(Sys.Date()),
  r_version = paste(R.version$major, R.version$minor, sep = '.'),
  lme4_version = as.character(packageVersion('lme4'))
)

out_file <- 'analysis/data/derived_data/seed_reproduction_check.csv'
utils::write.csv(check, out_file, row.names = FALSE)
print(check, n = Inf)
message(sprintf('%d replicates regenerated in %.1f s',
                length(rows), elapsed_sec))
