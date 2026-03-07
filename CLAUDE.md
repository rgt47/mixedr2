# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mixedr2** is an R package implementing a Monte Carlo simulation study comparing R-squared methods for linear mixed-effects models (LMMs). It follows the ADEMP simulation framework and targets a biostatistics journal. The project is at an early stage -- the package skeleton exists but `R/` source files have not yet been written.

Two plan documents define the scope:

- `docs/plan-short.md` -- 32 scenarios, 500 reps, 2 methods (Nakagawa-Schielzeth, Johnson), ~10 min runtime. Start here.
- `docs/plan-full.md` -- 324 scenarios, 1000 reps, 6 methods, ~5-6 hrs. Expansion target.

The structural template is **nof1_power** (`~/Dropbox/prj/res/06-nof1-power/nof1_power/`). Mirror its architecture for `R/` functions, simulation orchestration, parallel processing, and test layout.

## Build and Development

This is a zzcollab Docker-first project. Run `make help` for all targets.

```bash
# Docker workflow (recommended -- no local R needed)
make docker-build        # Build image from Dockerfile + renv.lock
make r                   # Enter interactive R session in container
make docker-test         # Run testthat suite in container
make docker-check        # R CMD check in container
make docker-render       # Render analysis/report/report.Rmd

# Native R (requires local R 4.5+)
make test                # devtools::test()
make check               # R CMD check --as-cran
make document            # devtools::document()

# Dependency validation (no R needed -- uses zzcollab CLI)
make check-renv          # Validate + auto-fix DESCRIPTION/renv.lock
make check-renv-no-fix   # Validate only, no modifications
```

Run a single test file natively:

```bash
Rscript -e "testthat::test_file('tests/testthat/test-generate_data.R')"
```

## Architecture

```
R/
  generate_data.R         # DGP: solve_dgp_params(), generate_lmm_data(),
                          #   create_scenario_grid()
  compute_r2.R            # Model fitting + R-sq extraction per method
  simulation.R            # Orchestration: run_single_replicate(),
                          #   run_scenario(), generate_simulated_results()
  parallel_utilities.R    # furrr/future setup (adapt from nof1_power)
  performance_metrics.R   # Bias, MSE, MCSE, monotonicity, boundary violations
  visualization.R         # Publication ggplot2 figures + theme_sim()
  math_utilities.R        # Variance decomposition helpers

analysis/
  scripts/simulation.R    # Top-level driver script
  scripts/analyze_results.R
  data/derived_data/      # .rds output (gitignored)
  report/report.Rmd       # Manuscript

tests/
  testthat/               # Unit tests (testthat 3e)
  integration/            # End-to-end pipeline tests
```

## Key Dependencies

- `lme4` -- model fitting (`lmer()`)
- `MuMIn` -- `r.squaredGLMM()` (Nakagawa-Schielzeth and Johnson methods)
- `furrr` / `future` -- parallel simulation via `future_map_dfr()`
- `renv` -- package management (lockfile is source of truth)

## Simulation Design

The DGP parameterization works by fixing target marginal R-squared and ICC, then solving analytically for beta, tau, and sigma. The `solve_dgp_params()` function encodes this mapping. Each scenario gets unique seeds per replicate for reproducibility.

Performance measures follow Morris et al. (2019): bias, relative bias, variance, MSE, monotonicity rate, boundary violation rate, with Monte Carlo standard errors.

## CI

GitHub Actions (`.github/workflows/r-package.yml`) runs R CMD check and testthat inside a `rocker/tidyverse` container with renv restore.

## Conventions

- Docker container sets `ZZCOLLAB_CONTAINER=true`; `.Rprofile` activates renv only inside the container
- `make r` runs `check-renv` before entering the container and validates on exit
- Auto-snapshot on R session exit updates `renv.lock` inside the container
- All R-squared extractors must be wrapped in `tryCatch()` to handle convergence failures
- Track `lme4::isSingular()` warnings; flag scenarios with >5% convergence failures
