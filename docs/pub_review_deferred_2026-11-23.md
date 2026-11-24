# pub_review Deferred-Item Pass: mixedr2
*2026-11-23 12:57 PST*

This pass covers the Deferred section of
`docs/pub_review_remediation_2026-08-16.md`, which answers
`docs/pub_review_whitepaper_2026-08-16.md`. Neither file was
edited. The later referee pass
(`analysis/report/referee-remediation-log-2026-11-17.md`,
uncommitted in the working tree, like most of its code and
manuscript changes) was used as evidence of later work. Its own
deferrals are not part of this inventory; they are pointed to in
Section 5. Nothing was committed or staged.

Environment: host R 4.6.2, `lme4` 2.0.1. `MuMIn` 1.48.19 and
`furrr` 0.4.0 are not installed on the host. They were installed,
with the current `mixedr2` source, into a session scratch library
used via `R_LIBS` (the scratch library from the 2026-11-17 pass
had been emptied by temp cleanup). All R ran single-threaded, one
process at a time. The baseline working-tree diff was saved before
any edit, so the file list below contains only this pass's
changes.

## 1. Inventory

| # | Source log item (Deferred, 2026-08-16) | Class |
|---|---|---|
| 1 | "Full render pipeline was actually run" (a note, not a deferral) | RESOLVED-SINCE |
| 2 | Sensitivity analysis over tau1/tau0 | DO-NOW (code and both full runs); reporting it is an author decision |
| 3 | Coverage as a performance measure (implementation) | AUTHOR-DECISION + LONG-RUN |
| 4 | Post-run `.Random.seed` capture per replicate | DO-NOW |
| 5 | Minor issue 1: author block / affiliation format | AUTHOR-DECISION |
| 6 | Full-scale tau-ratio or coverage reruns at 16,000-fit scale | LONG-RUN (coverage part only; the tau-ratio part is done under item 2) |
| 7 | Whitepaper 4(b): decide whether the six-method literature review belongs in the main text at its length (only the "at minimum" sentence-per-method part was done in August; the decision was neither Fixed nor Deferred) | AUTHOR-DECISION |

Totals: 7 items; 1 resolved-since; 0 no-longer-applies; 2 done
now (items 2 and 4); 1 long-run (item 6, coverage compute);
3 author-decision (items 3, 5, 7). Item 2 is done in the sense
that the code exists and both alternative ratios were run at full
scale; whether to report the results in the manuscript remains an
author decision (Section 4).

Item 1: the 2026-08-16 render is superseded by the 2026-11-17
renders (`analysis/report/share/report-2026-11-17-1832-662dbee-wip.pdf`)
and by this pass's render (below).

## 2. Done now

### Item 4: per-replicate RNG state `[verified]`

The 2026-04-17 audit asked for `.Random.seed` to be stored after
each replicate. Inspection of `R/generate_data.R` (line 22) shows
that each replicate calls `set.seed(seed)` on its own pre-drawn
seed, so its starting state is fixed by that seed and the RNG
kind, and no state carries between replicates. Storing
`.Random.seed` would add no information. The gap was instead
closed by checking reconstruction directly and by storing the
seed in future output.

- New `analysis/scripts/check_seed_reproduction.R`: rebuilds the
  main grid under L'Ecuyer-CMRG from master seed 20260306,
  regenerates the first and last replicate of all 32 scenarios
  (64 replicates) sequentially from their seeds alone, and compares
  every stored R-squared column of `sim_results.rds`. Result
  (`analysis/data/derived_data/seed_reproduction_check.csv`): all
  17 columns (full, reduced, null-augmented, omitted-slope, the
  adjusted R2m and the MuMIn cross-check) match with maximum
  absolute difference exactly 0. Run twice, before and after the
  code changes below, with identical results.
- `R/simulation.R::generate_simulated_results()` now writes the
  per-replicate `seed` column into the results. Effective only at
  the next full rerun; `sim_results.rds` was not modified.
- `analysis/report/report.Rmd`, ADEMP appendix: the
  `.Random.seed` bullet moved from "Gaps still open" to "Gaps
  closed", reporting the check through inline `r` expressions that
  read the CSV (new `seed-check` chunk). The text states that the
  current results file predates the seed column.
- Tests: `inst/tinytest/test-simulation.R` asserts that the seed is
  stored and that a stored seed regenerates its replicate exactly.

### Item 2, code part: `tau_ratio` plumbing `[verified]`

- `R/math_utilities.R::solve_dgp_params()` gains
  `tau_ratio = 0.5` in place of the hard-coded `0.5`.
- `R/generate_data.R::create_scenario_grid()` gains
  `tau_ratio = NULL`. With `NULL` no column is added, so scenario
  IDs, ordering and seeds of the main grid are unchanged (the
  manuscript cites scenario 17 by number). A supplied ratio adds a
  column only.
- `R/simulation.R::run_scenario()` reads an optional `tau_ratio`
  column (default 0.5); `generate_simulated_results()` records it
  when present.
- New `analysis/scripts/simulation_tau_ratio.R`: reruns only the
  16 random-slope scenarios at ratios 0.25 and 1 (or `--ratio=`),
  reusing the main grid's scenario IDs and seeds so each replicate
  is paired with the main run, writing
  `sim_results_tau_<ratio>.rds` and `sim_summary_tau_<ratio>.rds`.
  `--reps=K` runs a trial that validates and times but saves
  nothing. Sequential by default. The `--parallel` option is
  `[applied, unverified]`: it was never run, and because the script
  loads the source with `pkgload::load_all()` while `furrr` workers
  load the installed `mixedr2`, it requires a current installed
  copy of the package.
- Evidence that the default path is bitwise unchanged: the seed
  reconstruction check above (exact match on all 17 columns after
  the edit), plus new tests: default `tau_ratio` gives a parameter
  list identical to an explicit 0.5; a grid built with a ratio
  equals the default grid on all original columns; the ratio
  reaches `true_r2c` through `run_scenario()`; the target R2m is
  held at ratio 1; intercept-only scenarios ignore it.
- End-to-end trial: `--reps=5` for both ratios completed and
  passed its internal checks (12.7 s).
- Seed column downstream: the report and plotting code operate on
  `summarize_all_scenarios()` output, which is built per scenario
  from named columns, so an extra `seed` column in the results is
  not expected to reach any table. Inspected only; no report has
  yet been rendered from a results file that has the column. The
  tau-ratio result files (which do have it) did pass through
  `summarize_all_scenarios()` without error.

### Incidental fix `[verified]`

`report.Rmd` said "Two of the three gaps listed in that snapshot";
`docs/morris-audit-2026-04-17.md` lists four gaps (n_sim
justification, RNGkind pin, RNG-state capture, coverage). Now
"Three of the four", which is correct after item 4.

### Verification run

- `inst/tinytest`: 97 of 97 pass (83 before this pass plus 14 new
  assertions). `test-simulation.R` was run from a scratch copy with
  `setup_parallel(workers = 1)` instead of 2 to respect the
  machine limit; the file in the repo is unchanged on that line.
  With one worker `setup_parallel()` selects `future::sequential`,
  so the parallel-versus-sequential assertion did not exercise a
  worker process in this run.
- `tests/integration`: 10 of 10 pass.
- Render: `bash tools/render.sh analysis/report/report.Rmd`
  succeeded; staged `analysis/report/share/report-2026-11-23-1257-662dbee-wip.pdf`.
  `pdftotext` confirms the new appendix text with the computed
  values (64, 32, 17, 0) and no unresolved `??` references.

### Item 2, run part: tau-ratio sensitivity at full scale `[verified]`

Each ratio was run as its own single-threaded invocation, one at
a time: `Rscript analysis/scripts/simulation_tau_ratio.R
--ratio=0.25` (8.7 min) and `--ratio=1` (7.3 min), 16 random-slope
scenarios x 500 paired replicates each. (An earlier start with the
wrong arguments was killed at scenario 8 before saving; nothing was
written by it.) The save branch ran and its internal checks passed
(row count, seeds equal to the main grid, ratio recorded). New
files: `analysis/data/derived_data/sim_results_tau_0.25.rds`,
`sim_summary_tau_0.25.rds`, `sim_results_tau_1.rds`,
`sim_summary_tau_1.rds`. `sim_results.rds` and `sim_summary.rds`
are untouched. Convergence was 100% in all cells.

Ranges across the 16 slope cells (from the saved summaries;
the 0.5 row is the main run):

| tau1/tau0 | NS R2m bias | Johnson R2m bias | Johnson R2c bias | Omitted-slope R2m bias | Omitted-slope R2c bias | Johnson R2m bias > 2 MCSE |
|---|---|---|---|---|---|---|
| 0.25 | 0.0018 to 0.0165 | -0.0002 to 0.0109 | -0.0044 to 0.0441 | -0.0003 to 0.0110 | -0.0280 to 0.0099 | 8 of 16 |
| 0.5 | 0.0047 to 0.0315 | -0.0001 to 0.0119 | -0.0038 to 0.0370 | -0.0003 to 0.0122 | -0.0845 to -0.0052 | 8 of 16 |
| 1 | 0.0129 to 0.0894 | 0.0001 to 0.0151 | -0.0053 to 0.0217 | -0.0001 to 0.0193 | -0.2533 to -0.0481 | 9 of 16 |

Reading (not yet in the manuscript): the Johnson R2m bias is
nearly stable across ratios; the NS (2013) R2m error grows
roughly threefold from 0.5 to 1 and exceeds the Johnson error in
all 16 cells at every ratio; the omitted-slope R2c bias grows
sharply with the ratio. The manuscript's omitted-slope statement
(R2m bias "at most 0.012") holds at 0.5 but not at 1 (0.019).
These numbers were not added to `report.Rmd`.

## 3. Long runs
- **Coverage (items 3, 6).** No code written (see Section 4).
  Measured cost of a parametric bootstrap
  (`lme4::bootMer`, Johnson R2m and R2c, 50 refits): 0.006 s per
  refit at N = 100 (scenario 1) and 0.015 s at N = 1000
  (scenario 32), uncontended. At B = 1000 over 16,000 replicates
  this is on the order of 1e5 to 2.4e5 s (about 1 to 3 days
  single-threaded); at B = 200 roughly 5 to 13 hours. A reduced
  design (for example 200 replicates per cell, B = 500) is about
  5 to 13 hours. All are far over budget.
- **Seed column in `sim_results.rds`.** Only by a full rerun:
  `Rscript analysis/scripts/simulation.R` (about 14 minutes
  single-threaded by today's 0.05 s per replicate, or 19 to 24
  minutes with 7 workers under contention per the driver header).
  Not needed for reproducibility, given the check above.

## 4. Author decisions

- **Report the tau-ratio sensitivity?** The runs are done (Section
  2). Options: (a) add a short supplementary table read from
  `sim_summary_tau_*.rds` by inline `r`, and revise the
  Data-Generating Mechanisms paragraph ("We hope to take this up
  in future work"), the Results sentence on the
  slope-to-intercept ratio, and the Limitations paragraph that
  says the ratio "was not varied factorially"; (b) keep the
  disclosure only. Recommendation: (a). The results strengthen
  the main NS-versus-Johnson conclusion and qualify the
  omitted-slope conclusion, which the current text states only
  for ratio 0.5.
- **Coverage: which interval, and at what scale?** Options:
  parametric bootstrap percentile intervals (as in `partR2`);
  a delta-method SE (needs derivation for the variance-component
  ratio, unreliable near the boundary where many slope fits are
  singular); or keep coverage out with the existing Limitations
  disclosure. Recommendation: keep it out of this paper. The cost
  is days of compute, the paper's aims are bias, precision and
  monotonicity, and Recommendation 4 already rules out MCSEs as
  applied uncertainty.
- **Author block (Minor issue 1).** Current block: a single author
  with affiliation and ORCID in a `\thanks{}` footnote; the CSL is
  Statistics in Medicine. Whether this suffices depends on the
  target journal, which the whitepaper's Recommended Framing left
  open. Recommendation: choose the journal, then conform the block
  to that journal's author guidelines. (No journal's requirements
  were checked in this pass.)
- **Literature-review length (item 7).** Options: keep the
  six-method review in the main text, or move the four
  unevaluated methods to a supplement. Evidence: the 2026-11-17
  pass rewrote the review substantially (Edwards, Xu,
  Rights-Sterba), and it now carries verified corrections to the
  published record that are part of the paper's contribution.
  Recommendation: keep it in the main text, but shorten it if the
  target journal has a tight length limit.

## 5. New issues found

- **`man/` is empty while `NAMESPACE` uses `exportPattern`.** The
  roxygen blocks (including the new `tau_ratio` documentation)
  are not rendered. `devtools::document()` would also rewrite
  `NAMESPACE` into explicit `export()` lines, which would stop
  exporting any function lacking `@export`. Not run here; the
  2026-11-17 log also deferred it. Author should run
  `Rscript -e 'devtools::document()'` and review the
  `NAMESPACE` diff.
- **Earlier unverified fix now inspected.** The 2026-08-16 Figure 4
  filename rename is present (`analysis/scripts/analyze_results.R`
  line 41, `fig4_sample_icc_interaction.pdf`) `[inspected]`; the
  script was not run.
- **Other deferrals still open from 2026-11-17** (pointer only, not
  acted on): independent-G sensitivity arm, weak-predictor arm,
  archival DOI, container rerun, Edwards formula check, and stale
  descriptions in `CLAUDE.md` and `docs/plan-short.md`. See that
  log's Section 2.
- The parallel-equivalence test in `test-simulation.R` starts 2
  `furrr` workers; under the campaign's one-worker limit it was run
  with 1. Behavior with 2 workers was not re-run today.

## Files changed in this pass

`R/math_utilities.R`, `R/generate_data.R`, `R/simulation.R`,
`inst/tinytest/test-math_utilities.R`,
`inst/tinytest/test-generate_data.R`,
`inst/tinytest/test-simulation.R`, `analysis/report/report.Rmd`,
`docs/morris-audit-2026-04-17.md` (new dated 2026-11-23 addendum),
new `analysis/scripts/check_seed_reproduction.R`, new
`analysis/scripts/simulation_tau_ratio.R`, new
`analysis/data/derived_data/seed_reproduction_check.csv`, new
`analysis/data/derived_data/sim_results_tau_0.25.rds`,
`sim_summary_tau_0.25.rds`, `sim_results_tau_1.rds`,
`sim_summary_tau_1.rds`, and the
render outputs (`analysis/report/report.pdf`, `report.tex`,
`report_files/`, `share/MANIFEST.md`, new
`share/report-2026-11-23-1257-662dbee-wip.pdf`). The R, test and
Rmd files also carry earlier uncommitted 2026-11-17 changes.
