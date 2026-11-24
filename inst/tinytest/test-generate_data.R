library(tinytest)

# generate_lmm_data returns correct dimensions
params <- solve_dgp_params(0.10, 0.40, n_fixed = 2)
dat <- generate_lmm_data(
  n_clusters = 20, cluster_size = 5,
  params = params, seed = 42
)
expect_equal(nrow(dat), 100)
expect_true(all(c("y", "x1", "x2", "cluster_id") %in% names(dat)))
expect_equal(length(unique(dat$cluster_id)), 20)

# generate_lmm_data is reproducible with seed
params <- solve_dgp_params(0.10, 0.40, n_fixed = 2)
dat1 <- generate_lmm_data(20, 5, params, seed = 123)
dat2 <- generate_lmm_data(20, 5, params, seed = 123)
expect_identical(dat1, dat2)

# generate_lmm_data produces different data without seed
params <- solve_dgp_params(0.10, 0.40, n_fixed = 2)
dat1 <- generate_lmm_data(20, 5, params, seed = 1)
dat2 <- generate_lmm_data(20, 5, params, seed = 2)
expect_false(identical(dat1$y, dat2$y))

# generate_lmm_data empirical ICC near target (large sample)
params <- solve_dgp_params(0.10, 0.40, n_fixed = 2)
dat <- generate_lmm_data(
  n_clusters = 200, cluster_size = 50,
  params = params, seed = 999
)

fit <- lme4::lmer(y ~ x1 + x2 + (1 | cluster_id), data = dat)
vc <- as.data.frame(lme4::VarCorr(fit))
tau0_sq <- vc$vcov[vc$grp == "cluster_id"]
sigma_sq <- vc$vcov[vc$grp == "Residual"]
empirical_icc <- tau0_sq / (tau0_sq + sigma_sq)

expect_equal(empirical_icc, 0.40, tolerance = 0.15)

# create_scenario_grid produces correct grid size
grid <- create_scenario_grid(n_sim = 10)
n_scenarios <- 2 * 2 * 2 * 2 * 2
expect_equal(nrow(grid), n_scenarios * 10)
expect_equal(length(unique(grid$scenario_id)), n_scenarios)

# create_scenario_grid seeds are unique
grid <- create_scenario_grid(n_sim = 10)
expect_equal(length(unique(grid$seed)), nrow(grid))

# tau_ratio = NULL leaves the main-simulation grid unchanged; a
# supplied ratio only adds a column
expect_false('tau_ratio' %in% names(grid),
             info = 'default grid has no tau_ratio column')
grid_tau <- create_scenario_grid(n_sim = 10, tau_ratio = 1)
expect_identical(
  grid_tau[, names(grid)], grid,
  info = 'tau_ratio does not change scenario IDs or seeds'
)
expect_true(all(grid_tau$tau_ratio == 1), info = 'tau_ratio stored')
