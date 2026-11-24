# Referee Remediation Log: report.Rmd
*2026-11-17 18:33 PST*

This log records remediation of `referee-report-2026-11-17.md`
(same directory). The referee report was not edited. The
uncommitted voice-revision edits to `report.Rmd`
(`voice-revision-log-2026-11-17.md`) were kept and built on. New
and rewritten prose follows the short-sentence rule of
`use_rgtvoice.md`; a few sentences that carry an inline `r`
expression or a citation key run slightly long. Nothing was
committed, staged or pushed.

Evidence labels: `[verified]` means code was run and the output
was inspected; `[applied, unverified]` means the edit was made but
not executed or checked against a primary source.

## Environment used

`MuMIn` (1.48.19), `furrr` and `performance` (0.19.0) were not
installed on the host. They were installed, with `mixedr2`, into a
session scratch library (not the user library) and used via
`R_LIBS`. Host R is 4.6.0; `lme4` 2.0-1 and `MuMIn` 1.48.19 match
`renv.lock`. No container run was made. The manuscript states this.

## 1. Fixed

Major comments (all tier a).

- **M1 (the two arms were bitwise identical).** `R/compute_r2.R`
  now computes both estimators directly from the `lme4` fit via a
  new `r2_variance_components()`. NS (2013) uses
  $\hat\tau_0^2$ only; Johnson uses the mean of
  $\mathrm{diag}(Z\hat\Sigma Z^\top)$. `MuMIn::r.squaredGLMM()` is
  kept only as a cross-check (`extract_r2_mumin()`, stored as
  `mumin_r2m/c`). The full simulation was rerun. Result: Johnson
  matches MuMIn to 5.8e-15 in all 16,000 fits; NS equals Johnson
  exactly in all random-intercept fits; they differ in all but 41
  of 8,000 random-slope fits, and all 41 exceptions are singular
  fits. Abstract, Introduction, Johnson subsection, Table 1, Methods
  Under Comparison, Results, Discussion, Recommendations 1 to 2,
  Conclusions and Reproducibility were rewritten to match. The
  trigamma attribution and the `method = "trigamma"` description
  were removed. Regression tests added (arms differ in a slope
  fit; coincide in an intercept fit; Johnson equals
  $\overline{\mathrm{diag}}(ZGZ^\top)$ and equals MuMIn).
  `[verified]`
- **M2 ('approximately unbiased').** Removed. Results now report
  relative bias (new columns in Table 3), the count of cells with
  positive bias (29 of 32) and with bias above 2 MCSE (15 of 32),
  the worst cell (scenario 17, 11.9%), and the analytic source
  (the $\mathrm{tr}\{\mathrm{Var}(\hat\beta)S_x\}$ term). A cheap
  bias-adjusted comparator (`extract_r2m_adjusted()`) was added. Its
  absolute bias is at most 0.0072 and exceeds 2 MCSE in 3 of 32
  cells; it reduces |bias| in all 15 cells where the Johnson bias
  exceeds 2 MCSE. It over-corrects, however: its bias is negative in
  21 of 32 cells (-0.0072 to -0.0001 at N = 100) and larger in
  absolute value than Johnson's in 7. The manuscript reports these
  counts and calls the trace term a plausible main source, not a
  full explanation. Labeled exploratory, not a published estimator.
  These numbers agree with the referee's recomputation. `[verified]`
- **M3 ($R^2_c$ lower MSE than $R^2_m$).** Claim and mechanism
  removed. Replaced by counts from data: MSE($R^2_c$) < MSE($R^2_m$)
  in 9 of 16 cells at target 0.40 and 0 of 16 at target 0.10.
  `[verified]`
- **M4 (ICC-MSE claim).** Abstract, Results and Discussion claims
  removed. Results now report the paired comparison by target
  $R^2_m$ (higher ICC lowers MSE in 6 of 8 pairs at 0.10 and 1 of
  8 at 0.40) and make no general claim. `[verified]`
- **M5 (Aim 4 never implemented).** `run_single_replicate()` now
  fits a random-intercept-only model to random-slope data. New
  Results subsection 'Robustness to an Omitted Random Slope':
  $R^2_m$ bias at most 0.012, MSE 0.98 to 1.11 times the correct
  fit; $R^2_c$ bias -0.085 to -0.005. `[verified]`
- **M6 (literature review).** Edwards et al. rewritten as a
  Kenward-Roger Wald-$F$ statistic with
  $R^2_\beta = (q/\nu)F/\{1+(q/\nu)F\}$, null model with the same
  covariance structure, and the real `r2beta()` methods (`sgv`,
  `kr`, `nsj`, `lm`); the false `method = "lr"` and REML/ML
  critique removed. Johnson: trigamma attributed to Nakagawa et al.
  (2017), with the consequence for MuMIn stated. Xu (2003)
  rewritten as whole-model explained variation (three families of
  measures); level-specific pair attributed to Snijders and Bosker
  (1994) and Raudenbush and Bryk (2002). `performance` vs `MuMIn`:
  the unsourced model-matrix/fitted-values claim was replaced by our
  own check on 100 fits from five scenarios (agreement to 1e-14 in
  84 non-singular fits; `performance` returns no $R^2_c$ and a
  random-effects-free $R^2_m$ in the 16 singular fits). New
  subsection on the Rights-Sterba framework. Evidence:
  r2glmm methods `[verified]` (rdrr.io reference page); Edwards
  $F$-based definition and single-model, same-covariance null
  `[verified]` against Edwards (2010, arXiv:1011.0471) summary of
  the 2008 paper; the exact $(q/\nu)F$ formula is
  `[applied, unverified]` against the 2008 full text (paywalled; it
  is the standard form and matches the referee); Johnson/trigamma
  `[verified]` via MuMIn documentation and the 2014 abstract; Xu
  `[verified]` against the abstract plus the Rights-Sterba (2019)
  correspondence (Xu's measure maps to their total R2(fvm));
  `performance` comparison `[verified]` (run; script committed as
  `analysis/scripts/check_performance_agreement.R` and cited).
  Rights-Sterba claims (f1/f2/v/m/residual decomposition; ten
  earlier measures map to five of theirs; Johnson's extension
  equivalent in the sample; NS 2013 excluded slope variation)
  `[verified]` against the full text (author PDF). Level-specific
  variance-reduction measures re-attributed to Raudenbush and Bryk
  (2002), per Rights-Sterba; the exact Snijders-Bosker (1994)
  definition was not checked, so the text now only says they
  proposed 'a related level-1 and level-2 pair'.
- **M7 (monotonicity weakly designed), partial.** Added a null-predictor arm
  (pure-noise $x_3$, drawn after all DGP quantities so existing
  data are unchanged; tested) and $R^2_c$ monotonicity for both
  arms. New Table 4. Results: true-predictor $R^2_m$ rate at least
  97.8%; Johnson $R^2_c$ down to 87.2% (scenario 17); null
  predictor raises $R^2_m$ in only 47% to 77% of replicates and
  $R^2_c$ in 39% to 61%. The uninformative '> 0.95' sentence was
  removed; figure caption now says marginal $R^2$. `[verified]`
- **M8 (100% convergence by construction).** `fit_lmm()` now
  returns `conv_warning` (gradient/Hessian/eigenvalue messages from
  captured warnings or `optinfo`). Convergence section rewritten:
  1 of 16,000 full-model fits warned; warned and singular fits were
  retained. `[verified]`
- **M9 (MCSEs recommended for applied uncertainty).**
  Recommendation 4 rewritten: parametric bootstrap (as in
  `partR2`); MCSEs explicitly ruled out; coverage not evaluated.
  `[applied, unverified]` (prose only)

Minor comments (tier b).

- **1 Boundary violations.** Section removed; Performance Measures
  now says violations are impossible by construction. Recomputed
  rate is 0 in all cells for all estimators. `[verified]`
- **2 Relative bias and empirical SE.** Shown in Table 3.
  `[verified]`
- **3 'first systematic comparison'.** Removed from Conclusions.
  `[applied, unverified]`
- **4 Uncited claims.** 'vast majority' and 'required or strongly
  encouraged by many journals' both removed rather than cited.
  `[applied, unverified]`
- **5 ICC in slope scenarios.** Defined as the ICC at $x_1 = 0$ in
  Data-Generating Mechanisms. `[applied, unverified]`
- **6 Skew attribution.** Inline values (0.59 vs 0.66, matching the
  referee) now attribute skew to sample size. `[verified]`
- **7 Hard-coded figure numbers.** Replaced by `\@ref(fig:...)`;
  rendered PDF resolves them. `[verified]`
- **8 Unnumbered equations.** Key displayed equations now numbered
  with bookdown labels; Equation (3) cross-references resolve.
  `[verified]`
- **9 ADEMP section under References.** Moved to an appendix after
  `<div id="refs">`. `[verified]` (rendered)
- **10 Drifting date.** Fixed to 'November 17, 2026'. `[verified]`
- **11 `raudenbushHLM2002`.** Retyped `@book`. `[verified]`
- **12 n_sim justification.** Appendix and driver comment now use
  the worst cell (empirical SE 0.016 to 0.079; max bias MCSE
  0.0035) via inline `r`. `[verified]`
- **13 Repository URL.** Added `https://github.com/rgt47/mixedr2`
  (matches `git remote`). Partial: no archival DOI exists, so none
  was invented; the text says so. `[verified]`
- **14 Runtime projection.** Removed. `[applied, unverified]`

Missing references (tier b).

- Added `lahuisExplainedVarianceMeasures2014`,
  `rightsQuantifyingExplainedVariance2019`,
  `rightsNewRecommendationsUse2020` to `references.bib`, each
  confirmed by web search (journal, volume, pages, DOI), and cited
  in the Introduction, review and Results. Novelty claim narrowed to
  a finite-sample study of one estimator family. `[verified]`
  (bibliographic details) / rendered bibliography checked.

Suggestions (tier c), cheap parts only.

- 1 (partial): explicit NS (2013), independent Johnson, and
  bias-adjusted $R^2_m$ implemented; `performance` compared offline
  (not in the pipeline). 2 (partial): analytic bias source stated
  and tested via the adjusted estimator; no figure overlay.
  3 (partial): Aim 4 implemented. 6: regression test added.

## 2. Deferred

- **Minor 15 / Suggestion 3 (independent-$G$ fit,
  `(1 + x1 || cluster_id)`).** Out of budget. Disclosed in
  Limitations.
- **Weak-predictor arm (M7).** Only the null-predictor arm was
  added. Needs a design choice of effect size.
- **Suggestions 1 (`r2mlm`, `performance` in pipeline), 2 (overlay
  of the leading-order bias on Figure 1), 4 (bootstrap coverage),
  5 (vary $\tau_1/\tau_0$).** Out of budget.
- **Archival DOI.** Needs a Zenodo deposit by the author.
- **Container rerun.** Results were regenerated on host R 4.6.0
  outside Docker. To regenerate in the container:
  `make r` then `Rscript analysis/scripts/simulation.R`, then
  `make docker-render REPORT=analysis/report/report.Rmd`.
- **Roxygen `man/` pages** for the new exported functions
  (`r2_variance_components`, `extract_r2m_adjusted`,
  `extract_r2_mumin`) were not regenerated. Run
  `Rscript -e 'devtools::document()'`.
- **Edwards formula** should be checked against the 2008 full
  text (paywalled here).

- **Stale documentation outside the manuscript.** `CLAUDE.md`
  (line 72) and `docs/plan-short.md` (lines 83-84, 164-166) still
  describe the two arms as `r.squaredGLMM()` with and without
  `method = "trigamma"`. Not edited (project instructions and a
  historical plan); the author should update them.

## 3. New issues found while fixing

- **Parallel runs did not reproduce sequential runs.** furrr
  multisession workers start with R's default Mersenne-Twister RNG.
  The driver's `RNGkind("L'Ecuyer-CMRG")` was therefore not in force
  inside workers. The same seed gave different data in parallel and
  sequential execution. The shipped (pre-remediation)
  `sim_results.rds` matched the sequential L'Ecuyer path, so it was
  not produced by the current parallel driver in this environment.
  Fixed in `R/simulation.R::run_scenario()` (worker sets the
  caller's RNG kind) with a tinytest. The final rerun now matches
  the old file's MuMIn values exactly (max difference 0), so the
  new results are replicate-paired with the reviewed run.
  `[verified]`
- **Non-monotone $R^2$ under a null predictor.** Adding pure noise
  lowered $R^2_m$ in roughly 25% to 50% of replicates. This is a
  substantive finding, now reported, with a new Recommendation 5.
  `[verified]`
- **Runtime and the second run's exit code.** The two full runs
  took 23.9 and 18.6 minutes under heavy machine contention, above
  the 10-minute guidance. The first run was discarded because of
  the RNG bug above. The second run exited with code 1 after
  saving: the driver's header comment was edited while Rscript was
  still reading the file, so the trailing print step mis-parsed.
  The saved file was validated: 16,000 rows, 0 NA, its stored
  summary equals `summarize_all_scenarios()` of the results
  (`all.equal` TRUE), and its MuMIn values equal the reviewed
  run's exactly. The driver now parses cleanly.
- **Mechanism statements.** New Results prose initially offered
  untested mechanisms (noise lowering the denominator, REML
  re-estimation for the null-predictor result, zero slope variance
  for the 41 coincident slope fits, slope variance absorbed into
  the residual). Each is now deleted or stated as a plausible,
  unverified reason.

## Verification run

- `tinytest::run_test_dir('inst/tinytest')`: 83 of 83 pass.
- `tinytest::run_test_dir('tests/integration')`: 10 of 10 pass.
- Every inline `r` expression evaluated against the final
  `sim_results.rds`; each prose claim was checked against its value.
- Rendered with `bash tools/render.sh analysis/report/report.Rmd`
  twice; the final staged copy is
  `share/report-2026-11-17-1832-662dbee-wip.pdf` (an earlier
  `...-1826-...` copy is also in `share/`). No unresolved
  references in the PDF text. Lines were rewrapped after the final
  render (whitespace only).
