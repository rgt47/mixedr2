# pub_review Remediation Log
*2026-08-16 16:23 PDT*

This log records remediation of
`docs/pub_review_whitepaper_2026-08-16.md`. It is a separate,
new file; the whitepaper itself was not edited.

## 1. Fixed

- **Major issue 1 (Abstract design-parameter contradiction).**
  `analysis/report/report.Rmd`: rewrote the Abstract's Methods
  paragraph to pull ICC, target-$R^2_m$, `n_sim`, and total-fit
  counts via inline `r` expressions from a new `design-summary`
  chunk that reads `summary_table` (itself built from
  `sim_results.rds`), instead of hard-coded prose. Confirmed the
  rendered PDF now reads "32-scenario factorial... ICC \in
  \{0.10, 0.40\}... 500 replicates (16,000 model fits in
  total)", matching the executed grid and eliminating the
  possibility of future silent drift. `[verified]` — rendered via
  `bash tools/render.sh analysis/report/report.Rmd`; confirmed by
  `pdftotext` grep on the output PDF.

- **Major issue 2 (fabricated Reproducibility RNG description).**
  `analysis/report/report.Rmd`, Reproducibility section: rewrote
  the "Random-number generator" paragraph to describe the actual
  mechanism (`RNGkind("L'Ecuyer-CMRG")` pinned in
  `analysis/scripts/simulation.R`; master seed 20260306 consumed
  once inside `create_scenario_grid()` via `sample.int()` to
  pre-draw one seed per scenario-replicate; each replicate's seed
  consumed once by `set.seed()` inside `generate_lmm_data()`;
  `furrr::future_map_dfr()` with `seed = NULL` because seeding is
  handled explicitly upstream). Also corrected the package list,
  which had wrongly attributed the Johnson estimator to the
  `performance` package; both Nakagawa-Schielzeth and Johnson are
  computed via `MuMIn::r.squaredGLMM()` in `R/compute_r2.R`, and
  `performance` is not invoked anywhere in the pipeline. `[verified]`
  — confirmed by reading `R/generate_data.R`,
  `R/simulation.R::run_scenario()`, `R/compute_r2.R`, and
  `analysis/scripts/simulation.R`, and by the rendered PDF.

- **Major issue 3 (stale in-manuscript ADEMP self-audit).**
  `analysis/report/report.Rmd`, "Morris et al. (2019) ADEMP
  Compliance" section: rewrote to separate "Gaps closed since the
  prior audit" (n_sim MCSE justification; RNGkind pin — both
  confirmed present in `analysis/scripts/simulation.R`) from
  "Gaps still open" (no post-run `.Random.seed` capture; no
  coverage measure). Also updated
  `docs/morris-audit-2026-04-17.md` with a dated
  "2026-08-16 re-audit addendum" recording which of the original
  five gaps are now Met vs. still open, rather than leaving the
  original audit's stale verdict standing unqualified. `[verified]`
  — re-inspected `analysis/scripts/simulation.R` lines 15 and
  24-29 directly; rendered PDF confirms the corrected text.

- **Major issue 4 (undisclosed $\tau_1 = 0.5\,\tau_0$
  convention).** `analysis/report/report.Rmd`, "Data-Generating
  Mechanisms": added a paragraph disclosing the convention
  explicitly, with the rationale (a single, moderate,
  reproducible slope-to-intercept variance ratio, not solved for
  from ICC/target $R^2_m$) and an explicit scope statement that
  the random-slope results are conditional on this one ratio.
  Added a matching paragraph to Limitations. A full factorial
  sensitivity analysis over $\tau_1/\tau_0$ was judged out of the
  remediation time budget and is left as a noted future-work item
  rather than run partially and risk a misleading partial result.
  `[applied, unverified]` — text change only; no new simulation
  was run for this item.

- **Major issue 5 (overclaimed novelty vs. uncited literature).**
  `analysis/report/report.Rmd`: added `@piephoCoefficientDetermin
  ationR22019` and `@stoffelPartR2Partitioning2021` citations to
  the Introduction with an explicit statement of how each relates
  to (and does not duplicate) this study's scope, added a new
  "The `partR2` Package (Stoffel et al., 2021)" subsection under
  the literature review, narrowed the novelty claim in the
  Abstract and Introduction to the two-method comparison, and
  retitled the manuscript to
  "Bias, Precision, and Monotonicity of Marginal and Conditional
  R-Squared for Linear Mixed Models: A Monte Carlo Comparison of
  the Nakagawa-Schielzeth and Johnson Estimators" per the
  whitepaper's Recommended Framing (Section 5). Also cited the
  three remaining previously-unused `.bib` entries
  (`raudenbushHLM2002`, `snijdersMultilevelAnalysis2012`,
  `burtonDesignAnalysisMonteCarlo2006`) in context rather than
  deleting them, resolving desirable-polish item in the same
  pass. `[verified]` — a citation-key cross-check
  (`grep -oE '@[a-zA-Z0-9]+' report.Rmd` vs. `references.bib`
  entries) confirms zero cited-but-missing and zero
  unused-but-present keys after the edit; rendered PDF confirms
  citations resolve.

- **Acceptance item: coverage as a performance measure.**
  `analysis/report/report.Rmd`, Limitations: added an explicit
  disclosure of why coverage is not reported (neither
  `MuMIn::r.squaredGLMM()` variant returns an analytic SE/interval
  for $\hat{R}^2$; adding one would require a bootstrap or
  delta-method addition to `R/compute_r2.R`, out of scope for this
  revision) and named it as a concrete target for
  `R/performance_metrics.R` in a future revision. `[applied,
  unverified]` — disclosure only; coverage was not implemented.

- **Acceptance item: correlated-vs-independent random-effects
  disclosure (Minor issue 3).** `analysis/report/report.Rmd`,
  Limitations: added a paragraph disclosing that the DGP draws
  $b_{0i}$ and $b_{1i}$ independently
  (`R/generate_data.R`) while the fitted model uses `lme4`'s
  default correlated-random-effects parameterization
  (`R/compute_r2.R::fit_lmm()`), and connecting this to the
  elevated singular-fit rate in low-ICC random-slope scenarios.
  `[verified]` — confirmed by reading both source files directly.

- **Acceptance item: one-sentence-per-unevaluated-method
  rationale.** `analysis/report/report.Rmd`, "Summary of
  Methods": replaced the generic "candidates for future work"
  sentence with a specific, one-clause reason for excluding each
  of Edwards et al., Jaeger et al., Xu, and `performance` from the
  empirical comparison (estimand mismatch, no maintained package,
  and near-identical numerics to a method already compared,
  respectively). `[applied, unverified]` — text-only change,
  reasons are consistent with the literature-review content
  already in the manuscript but were not independently
  re-verified against the cited packages' source code.

- **Acceptance item: integration/end-to-end pipeline test (Minor
  issue 4).** Added `tests/integration/test-pipeline.R`, a real
  tinytest suite that runs `create_scenario_grid()` ->
  `generate_simulated_results()` -> `summarize_all_scenarios()`
  at reduced scale (2 scenarios x 30 reps) and asserts on
  convergence, absence of NAs, summary-table structure, valid
  monotonicity proportions, small bias, and correct true-$R^2_m$
  recovery. Wired it into `tests/tinytest.R` (previously only
  `test_package("mixedr2")`, which does not discover
  `tests/integration/`) via an explicit
  `tinytest::run_test_dir("integration")` call. `[verified]` — ran
  directly with
  `Rscript -e 'pkgload::load_all("."); tinytest::run_test_dir("tests/integration")'`;
  10/10 assertions pass in 6.7s.

- **Desirable polish: Figure 4/5 filename mismatch (Minor issue
  2).** `analysis/scripts/analyze_results.R`: renamed the output
  file for `plot_sample_size_icc_interaction()` from
  `fig5_sample_icc_interaction.pdf` to
  `fig4_sample_icc_interaction.pdf`, matching the manuscript
  prose ("Figure 4 shows...") and the chunk's actual position as
  the fourth `fig.cap` chunk in `report.Rmd`. `[applied,
  unverified]` — the script was not re-run end-to-end (it depends
  on `sim_results.rds`, `plot_*` functions, and writes to a
  gitignored `analysis/figures/` directory); the rename itself
  was verified by re-reading the edited file.

- **Desirable polish: unverified 5-6 hour runtime estimate (Minor
  issue 5).** `analysis/report/report.Rmd`, Limitations: reworded
  to explicitly label the figure as "estimated (not benchmarked)"
  and "a rough projection only," per the whitepaper's remediation
  instruction, rather than removing the number outright.
  `[verified]` — confirmed no benchmark data exists in the repo
  (`analysis/data/derived_data/` contains only the 32-scenario/
  500-rep and 10-rep pilot outputs, nothing at 324-scenario
  scale).

## 2. Deferred

- **Full render pipeline was actually run**, so this is not
  deferred: `bash tools/render.sh analysis/report/report.Rmd`
  succeeded and `analysis/report/report.pdf` /
  `analysis/report/share/report-2026-08-16-1622-*.pdf` reflect
  all text changes above. Noted here only because the
  remediation instructions treat rendering as optional and it is
  worth stating plainly that it was in fact completed.

- **Sensitivity analysis over the $\tau_1/\tau_0$ ratio** (Major
  issue 4's second remediation option). Disclosure was completed;
  the factorial sensitivity run itself (varying
  $\tau_1/\tau_0 \in \{0.25, 0.5, 1.0\}$, doubling or tripling the
  random-slope scenario count) was not attempted because it
  requires a new simulation design decision (how many levels, at
  what sub-sample of the existing 16 random-slope scenarios) best
  made by the author, not just a mechanical rerun. To run a
  reduced version: extend `create_scenario_grid()` with a
  `tau_ratio` argument, thread it through
  `R/math_utilities.R::solve_dgp_params()` in place of the
  hard-coded `0.5`, and re-run
  `Rscript analysis/scripts/simulation.R --pilot` first to sanity
  check before a full run.

- **Coverage as a performance measure** (implementation, not just
  disclosure). Requires adding a bootstrap or delta-method SE for
  $\hat{R}^2_m$/$\hat{R}^2_c$ to `R/compute_r2.R` and a
  `calculate_coverage()` function to `R/performance_metrics.R`,
  which is new statistical/software work beyond a remediation
  pass, not a bug fix. Command to prototype once implemented:
  `Rscript analysis/scripts/simulation.R --pilot` followed by
  `tinytest::run_test_dir("inst/tinytest")` to check the new
  function before a full rerun.

- **Post-run `.Random.seed` capture per replicate.** Same
  category as coverage: a genuine feature addition to
  `run_single_replicate()` (append `.Random.seed` to a sidecar
  RDS), not a defect fix, and not attempted given the correctness-
  first budget priority.

- **Minor issue 1 (author-block/affiliation format).** Requires a
  decision about the target journal (see Recommended Framing,
  whitepaper Section 5, which itself recommends narrowing the
  target venue) before the affiliation block can be conformed to
  a specific journal's house style. No change made.

- **Full-scale $\tau_1/\tau_0$ or coverage reruns at 16,000-fit
  scale.** Not attempted; see the two items above. The existing
  `sim_results.rds` (16,000 fits, 100% convergence, no NAs) was
  verified as genuine and was not regenerated, since no bug was
  found in the driver that produced it.

## 3. New issues found while fixing

- The Reproducibility section's package list mis-attributed the
  Johnson trigamma estimator to the `performance` package; the
  code uses `MuMIn::r.squaredGLMM(method = "trigamma")`
  exclusively, and `performance` is never invoked in the
  simulation pipeline despite being a `Suggests` dependency. Not
  flagged explicitly in the original whitepaper's Major issue 2
  (which focused on the seeding mechanism), but caught while
  rewriting that same paragraph and fixed as part of the same
  edit (see Fixed, Major issue 2).

- `tests/tinytest.R` ran only `test_package("mixedr2")`, which
  discovers `inst/tinytest/` but not `tests/integration/`; the
  latter directory was therefore not only empty (as the
  whitepaper's Minor issue 4 noted) but, even once populated,
  would not have been executed by the project's own test runner
  without the explicit `run_test_dir("integration")` call added
  here. This is a runner-wiring gap the whitepaper did not
  specifically call out.

- `CLAUDE.md` in this repo still documents `tests/testthat/` and
  `devtools::test()` as the test workflow (a stale early-stage
  scaffold), while the project's actual, working test suite uses
  `tinytest` exclusively (`inst/tinytest/`, `tests/tinytest.R`).
  This is a repository-hygiene inconsistency, not a manuscript
  defect, and was not corrected here since `CLAUDE.md` is outside
  the whitepaper's and this remediation task's scope.
