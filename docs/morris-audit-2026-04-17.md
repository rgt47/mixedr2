# Morris et al. (2019) ADEMP Audit: 17-mixed-r2
*2026-04-17 09:02 PDT*

## Scope

Files audited:

- `analysis/scripts/simulation.R`
- `R/performance_metrics.R`
- `R/generate_data.R`
- `analysis/report/report.Rmd`

## ADEMP scorecard

| Criterion | Status | Evidence |
|---|---|---|
| Aims explicit | Partial | goals stated; ADEMP heading not used explicitly |
| DGMs documented | Met | `create_scenario_grid()` in `generate_data.R:73-102` |
| Factors varied factorially | Met | factorial grid implemented |
| Estimand defined with true value | Met | R^2 inputs to the DGM |
| Methods justified | Met | R^2 estimators compared |
| Performance measures justified | Met | bias, MSE, rejection rate tied to aims |
| n_sim stated | Met | `n_sim = 500` at `analysis/scripts/simulation.R:18` |
| n_sim justified via MCSE | Not met | no explicit derivation |
| MCSE reported per metric | Met | `calculate_mcse_bias`, `calculate_mcse_mse`, `calculate_mcse_proportion` at `R/performance_metrics.R:81-112`, applied in `summarize_performance()` L132-189 |
| Seed set once | Met | `master_seed = 20260306`; per-replicate seeds drawn from master at `generate_data.R:81` |
| RNG states stored | Partial | pre-generated seeds available; `.Random.seed` not explicitly captured post-run |
| Paired comparisons | Met | same data fed to competing methods per rep |
| Reproducibility | Met | master seed + per-rep seeds; RNGkind not pinned |

## Overall verdict

**Mostly compliant.** This repo is the closest-to-compliant in the
portfolio. MCSE is computed systematically. Gaps are narrow: n_sim
justification text, `RNGkind()` pin, explicit post-run state capture,
and a coverage performance measure.

## Gaps

- No n_sim = 500 MCSE justification paragraph in `report.Rmd`.
- `RNGkind("L'Ecuyer-CMRG")` not pinned, so exact reproducibility
  across R versions is not guaranteed.
- Post-run `.Random.seed` capture per replicate absent (pre-generated
  seeds are stored but the state at the end of each replicate is not).
- Coverage is not among the reported performance measures despite
  being standard for R^2-estimator evaluation.

## Remediation plan

1. In `analysis/scripts/simulation.R` around line 18, add a comment
   block deriving n_sim from a target MCSE (e.g., for bias MCSE ≤
   0.002 at observed emp SE ≈ 0.04, need n ≥ 400 — so 500 is
   sufficient).
2. Pin `RNGkind("L'Ecuyer-CMRG")` immediately before the `set.seed()`
   call.
3. Extend `run_single_replicate()` to append `.Random.seed` post-run
   to a sidecar RDS in `analysis/data/derived_data/rng_states.rds`.
4. Add coverage as a performance measure in `R/performance_metrics.R`
   alongside bias / MSE / rejection; wire the `mcse_coverage` formula
   (already implemented as `mcse_proportion`) into the summary.
5. Add an ADEMP heading block to `report.Rmd` that cites Morris Table
   6 and documents the mapping of aims to metrics.

## References

Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate
statistical methods. Stat Med 2019;38:2074-2102. doi:10.1002/sim.8086

---
*Source: ~/prj/res/17-mixed-r2/mixedr2/docs/morris-audit-2026-04-17.md*
