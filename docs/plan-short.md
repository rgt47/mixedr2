# Simulation Study: R-squared for LMMs (Short Plan)

## Context

Multiple competing R-squared definitions exist for linear mixed-effects
models (LMMs), yet no systematic simulation study compares their
statistical properties under controlled conditions. This project
compares the two most widely used approaches -- Nakagawa & Schielzeth
(2013) and Johnson (2014) -- via Monte Carlo simulation, following the
ADEMP framework. The simulation is scoped to run in approximately 10
minutes. The target venue is a biostatistics journal (e.g., Statistics
in Medicine, Biometrical Journal).

## Project Location

`~/prj/res/17-mixed-r2/mixedr2/` -- initialized via `zzc`.

## Reference Template

**nof1_power** (`~/Dropbox/prj/res/06-nof1-power/nof1_power/`) is the
structural template. This project mirrors its architecture: an R package
with `R/` functions, furrr-based parallel simulation, Morris et al.
(2019) MCSE tracking, Docker-first zzcollab build, and testthat 3e.

Key files to model on:

- `R/generate_data.R` -- DGP pattern (our `R/generate_data.R`)
- `R/simulation.R` -- simulation orchestration with
  `generate_simulated_results()` (our `R/simulation.R`)
- `R/analysis.R` -- model fitting pipeline (our `R/compute_r2.R`)
- `R/parallel_utilities.R` -- furrr/future setup, globals export
  (reuse directly)
- `R/visualization.R` -- ggplot2 plotting (our `R/visualization.R`)
- `analysis/scripts/simulation.R` -- top-level script driving the run
- `analysis/report/report.Rmd` -- manuscript structure
- `Makefile` -- Docker-first targets
- `DESCRIPTION` -- package metadata
- `tests/testthat/` + `tests/integration/`

---

## ADEMP Design

### Aims

1. **Accuracy**: How well does each R-squared recover the true
   proportion of variance explained (marginal and conditional)?
2. **Sensitivity**: How do measures respond to ICC, sample size,
   cluster size, and random effects complexity?
3. **Monotonicity**: When a true predictor is added, does R-squared
   always increase?
4. **Robustness**: How do measures behave under model misspecification
   (omitted random slope)?

### Data-Generating Mechanisms

Base model:
`y_ij = beta_0 + beta_1*x1_ij + beta_2*x2_ij + b_0i + b_1i*x1_ij + eps_ij`

| Factor | Levels | Count |
|--------|--------|-------|
| Clusters (J) | 20, 50 | 2 |
| Cluster size (n) | 5, 20 | 2 |
| ICC | 0.10, 0.40 | 2 |
| Target marginal R-sq | 0.10, 0.40 | 2 |
| Random effects | Intercept-only, Intercept+slope | 2 |

32 scenarios x 500 replications = 16,000 fits. At ~0.05s per fit
(2 methods per fit), this runs in ~10 minutes on 8 cores.

Parameterization: fix target R2_marginal and ICC, solve analytically
for beta, tau, sigma.

### Estimands (True R-squared)

- **Marginal**: `R2_m = Var(X*beta) / Var(Y)`
- **Conditional**: `R2_c = (Var(X*beta) + Var(random)) / Var(Y)`

### Methods

| Method | Package / Function | Output |
|--------|--------------------|--------|
| Nakagawa-Schielzeth (2013) | `MuMIn::r.squaredGLMM()` | Marginal + conditional |
| Johnson (2014) | `MuMIn::r.squaredGLMM(method="trigamma")` | Marginal + conditional |

### Performance Measures

Bias, relative bias, variance, MSE, monotonicity rate, boundary
violation rate, Monte Carlo SE (per Morris et al., 2019).

---

## Project Structure (mirroring nof1_power)

```
mixedr2/
  DESCRIPTION                   # R package metadata
  NAMESPACE                     # roxygen2-generated exports
  LICENSE
  CLAUDE.md                     # Project-specific instructions
  Makefile                      # Docker-first (zzcollab pattern)
  Dockerfile
  renv.lock / .Rprofile
  .Rbuildignore / .gitignore
  README.md
  R/
    generate_data.R             # DGP: generate_lmm_data(),
                                #   solve_dgp_params(),
                                #   create_scenario_grid()
    compute_r2.R                # R-sq extraction: compute_all_r2(),
                                #   fit_and_extract_r2()
    simulation.R                # Orchestration:
                                #   run_single_replicate(),
                                #   run_scenario(),
                                #   generate_simulated_results()
    parallel_utilities.R        # Adapted from nof1_power
    performance_metrics.R       # Bias, MSE, MCSE, monotonicity,
                                #   boundary violations
    visualization.R             # Publication figures
    math_utilities.R            # Variance decomposition helpers
    packagedocumentation.R      # roxygen2 package-level doc
  tests/
    testthat.R
    testthat/
      test-generate_data.R
      test-compute_r2.R
      test-simulation.R
      test-performance_metrics.R
    integration/
      test-data-pipeline.R
      test-report-rendering.R
  analysis/
    scripts/
      simulation.R              # Top-level simulation driver
      analyze_results.R         # Post-simulation summaries
    data/
      derived_data/             # .rds/.RData (gitignored)
    figures/                    # .pdf/.png (gitignored)
    tables/
    report/
      report.qmd                # Main manuscript (Quarto)
      supplementary.qmd
      references.bib
      _quarto.yml
```

---

## R/ File Details

### `R/generate_data.R`

- `solve_dgp_params(target_r2m, target_icc, n_fixed, re_structure, sigma2 = 1)`
  Returns named list of beta, tau_0, tau_1, sigma.
- `generate_lmm_data(n_clusters, cluster_size, params, seed)`
  Generates one dataset. Returns tibble with y, x1, x2, ..., cluster_id.
- `create_scenario_grid(n_sim, ...)`
  Full factorial grid with unique seeds per replicate.

### `R/compute_r2.R`

- `fit_lmm(data, formula)` -- fits `lme4::lmer()`, returns model +
  diagnostics
- `extract_r2_nakagawa(model)` -- wraps `MuMIn::r.squaredGLMM()`
- `extract_r2_johnson(model)` -- wraps
  `MuMIn::r.squaredGLMM(method="trigamma")`
- `compute_all_r2(model)` -- calls both extractors, returns tibble row
- Each extractor wrapped in `tryCatch()`

### `R/simulation.R`

- `run_single_replicate(params, seed)` -- generate data, fit full +
  reduced models, extract R-sq, return tibble row
- `run_scenario(scenario_params, n_sim, seeds, use_parallel)` --
  map over replicates for one scenario
- `generate_simulated_results(scenario_grid, use_parallel, verbose)` --
  top-level orchestration across all scenarios
- `summarize_scenario(replicate_results, true_r2)` -- compute
  performance metrics for one scenario

### `R/parallel_utilities.R`

Adapt directly from nof1_power's `parallel_utilities.R`:

- `setup_parallel_processing(workers, strategy)`
- `prepare_parallel_globals()` -- export package functions to workers
- `teardown_parallel()` -- clean up future plan

### `R/performance_metrics.R`

- `calculate_bias(estimates, truth)`
- `calculate_relative_bias(estimates, truth)`
- `calculate_mse(estimates, truth)`
- `calculate_monotonicity_rate(r2_full, r2_reduced)`
- `calculate_boundary_violations(estimates)`
- `calculate_mcse_proportion(p, n_sim)` -- Morris et al. (2019)
- `calculate_mcse_bias(estimates, n_sim)`
- `calculate_mcse_mse(estimates, truth, n_sim)`
- `summarize_simulation_performance(results)` -- comprehensive table

### `R/visualization.R`

- `plot_bias_heatmap(summary_data)` -- Fig 1
- `plot_r2_distributions(raw_results, scenarios)` -- Fig 2
- `plot_monotonicity_rates(summary_data)` -- Fig 3
- `plot_misspecification_bias(summary_data)` -- Fig 4
- `plot_sample_size_icc_interaction(summary_data)` -- Fig 5
- `theme_sim()` -- consistent publication theme

---

## Manuscript Outline (Quarto)

1. **Introduction** -- Effect size reporting in mixed models;
   competing R-sq definitions; gap in simulation evidence
2. **Background** -- Mathematical review of each method with table
3. **Simulation Design** -- ADEMP sections 3.1-3.5
4. **Results** -- Bias/MSE (Fig 1), distributions (Fig 2),
   monotonicity (Fig 3), misspecification (Fig 4),
   sample size x ICC interactions (Fig 5)
5. **Discussion** -- Practical recommendations; limitations
6. **Conclusions**
7. **Supplementary** -- Full scenario tables, code availability

Key tables: DGP parameters, methods summary, bias/MSE for marginal
R-sq, bias/MSE for conditional R-sq, monotonicity rates, boundary
violations.

---

## Implementation Sequence

1. Initialize project with `zzc` at `~/prj/res/17-mixed-r2/mixedr2/`
2. Set up DESCRIPTION, renv, .gitignore, Makefile (from nof1_power)
3. Write `R/math_utilities.R` -- variance decomposition helpers
4. Write `R/generate_data.R` -- DGP functions + scenario grid
5. Write + run tests for steps 3-4
6. Write `R/compute_r2.R` -- R-sq extraction wrappers
7. Write + run tests for step 6
8. Adapt `R/parallel_utilities.R` from nof1_power
9. Write `R/simulation.R` -- orchestration
10. Write `R/performance_metrics.R` + tests
11. Write `analysis/scripts/simulation.R` -- driver script
12. Pilot simulation (10 reps, reduced grid)
13. Write `R/visualization.R` + figure generation
14. Write `analysis/scripts/analyze_results.R`
15. Draft Quarto manuscript (`analysis/report/report.qmd`)
16. Full simulation run (~10 min on 8 cores)
17. Finalize manuscript and supplementary

---

## Verification

- **DGP validation**: 10,000 datasets at known params; verify
  empirical ICC & R-sq match targets within MCSE
- **Analytical benchmark**: Random-intercept + 1 predictor has
  closed-form R-sq; verify at J=50, n=20, 500 reps
- **Convergence monitoring**: Track `lme4::isSingular()` and warnings;
  flag if >5% fail (nof1_power pattern)
- **Pilot run**: 10 reps x reduced grid before full simulation
- **Reproducibility**: Unique seeds per replicate, `renv` lockfile,
  `Makefile` targets (`make docker-test`, `make docker-render`)
- **Integration tests**: End-to-end pipeline test (generate -> fit ->
  extract -> summarize), modeled on nof1_power's `tests/integration/`

## Computational Notes

- 32 scenarios x 500 reps = 16,000 fits at ~0.05s each = ~13 min
  sequential, ~10 min on 8 cores (overhead from parallelization)
- Save results as single `.rds` file
- Memory: negligible (max ~1K rows per dataset)
- Parallel strategy: `furrr::future_map_dfr()` with
  `future::multisession` (nof1_power pattern)
