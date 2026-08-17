# Referee Review: Comparing R-Squared Measures for Linear Mixed Models

*Review date: 2026-08-16 16:05 PDT*

This white paper reviews the manuscript and supporting simulation
code in the `mixedr2` research compendium
(`~/prj/res/17-mixed-r2/mixedr2`), applying the standards of a
referee for a statistical/biostatistical journal (e.g., JASA,
Biometrics, JCGS, Statistics in Medicine). No prior `pub_review`
whitepaper exists for this repository, so this is a first-pass
review, not an update.

## 1. Summary of the work under review

The repository contains one manuscript,
`analysis/report/report.Rmd` ("Comparing R-Squared Measures for
Linear Mixed Models: A Monte Carlo Simulation Study"), an
ADEMP-structured Monte Carlo comparison of two competing $R^2$
definitions for linear mixed-effects models (LMMs): the
Nakagawa-Schielzeth (2013) marginal/conditional decomposition and
its Johnson (2014) trigamma extension for random-slope models. The
design crosses five binary factors (cluster count $J \in
\{20,50\}$, cluster size $n \in \{5,20\}$, ICC $\in \{0.10,
0.40\}$, target marginal $R^2 \in \{0.10, 0.40\}$, and random-effects
structure intercept-only vs. intercept+slope), yielding 32
scenarios, each run for 500 replicates (16,000 total model fits).
Variance components are solved analytically from the target
marginal $R^2$ and ICC so the true $R^2_m$ and $R^2_c$ are known
exactly, and performance is assessed via bias, relative bias, MSE,
monotonicity rate, boundary-violation rate, and Monte Carlo
standard errors (MCSEs) following Morris, White, and Crowther
(2019). The manuscript also contains a literature-review section
covering six $R^2$ proposals for LMMs (Nakagawa-Schielzeth,
Johnson, Edwards et al., Jaeger et al., Xu, and the `performance`
package), of which only the first two are actually simulated. The
reported conclusion is that the two methods are empirically
interchangeable for random-intercept models and that the Johnson
extension is modestly preferable for random-slope models, with
small-sample and low-ICC settings flagged as unreliable.

No other `.Rmd`/`.qmd`/`.tex`/`.md` manuscript exists in
`analysis/`, `docs/`, `paper/`, `manuscript/`, or `vignettes/`
(the latter is empty). `docs/plan-short.md` and `docs/plan-full.md`
are planning documents, not manuscripts, and
`docs/morris-audit-2026-04-17.md` is a prior internal audit; both
are treated as supporting material below rather than as
independent reports. Coherence-across-reports assessment (item 2
of the review scope) is therefore not applicable — there is a
single manuscript.

## 2. Major issues

1. **Abstract contradicts the simulation design reported in the
   body, on three separate numbers.** Location:
   `report.Rmd`, Abstract (lines 68-102) vs. `report.Rmd` Simulation
   Design (lines 396-436) and `analysis/scripts/simulation.R`
   (lines 24-32). The abstract states ICC $\in \{0.1, 0.5\}$,
   target marginal $R^2 \in \{0.1, 0.5\}$, and "1,000 replicates"
   per scenario. The body text, the DGP factor table
   (`dgp_df`), `R/generate_data.R::create_scenario_grid()` (defaults
   `iccs = c(0.10, 0.40)`, `r2ms = c(0.10, 0.40)`), and
   `analysis/scripts/simulation.R` (`n_sim <- 500`, "32 scenarios x
   500 reps = 16,000 fits") all agree on 0.10/0.40 and 500
   replicates. **Verified by inspection** of both the manuscript
   text and the executed driver script. This is not a rounding
   difference; 0.5 vs. 0.4 and 1,000 vs. 500 are different numbers
   that a referee would flag immediately, and 1,000 replicates with
   ICC/R2m $\in \{0.1,0.5\}$ matches the parameters proposed for the
   *unexecuted* six-method expansion in `docs/plan-full.md`, which
   suggests the abstract was drafted from the aspirational
   full-design plan and never reconciled with the design that was
   actually run. **Remediation:** rewrite the abstract to match the
   executed design (ICC and target $R^2_m \in \{0.10, 0.40\}$, $n_{sim}=500$,
   16,000 fits), and add a check (e.g., a `knitr` inline expression
   pulling the levels from `summary_table` rather than hard-coded
   prose) so the abstract cannot silently drift from the executed
   grid again.

2. **The Reproducibility section describes an RNG procedure that
   does not match the code that produced the results.** Location:
   `report.Rmd`, "Reproducibility" (lines 769-773) vs.
   `R/generate_data.R::create_scenario_grid()` (lines 73-102) and
   `R/simulation.R::run_scenario()` (lines 105-112). The manuscript
   states "The simulation driver sets `set.seed(20260411)` at the
   top of the replicate loop and uses `furrr::future_map` with
   `.options = furrr_options(seed = TRUE)` for parallel-safe RNG.
   Per-replicate seeds derive from the master seed by `+ rep_idx`."
   **Inspected**: none of this matches the code. There is no
   `set.seed(20260411)` anywhere in the repository (checked
   `analysis/scripts/simulation.R` and all of `R/`); the actual
   master seed is `create_scenario_grid(master_seed = 20260306)`,
   which pre-draws all per-replicate seeds with
   `sample.int(.Machine$integer.max, total_reps)` (not `master_seed
   + rep_idx`); and `run_scenario()` calls `furrr::future_map_dfr`
   with `furrr_options(seed = NULL, ...)`, not `seed = TRUE`. Using
   `seed = NULL` is defensible here because each replicate already
   receives an explicit, pre-drawn seed consumed by `set.seed(seed)`
   inside `generate_lmm_data()`, so the furrr-level seeding is
   redundant rather than absent — but the manuscript does not
   describe the mechanism that is actually used, and a reader who
   tried to independently reproduce a specific replicate using the
   documented "`master_seed + rep_idx`" rule would compute the wrong
   seed. For a paper whose main methodological hook is transparent,
   reproducible Monte Carlo evaluation, an inaccurate reproducibility
   statement is a substantive defect, not a stylistic one.
   **Remediation:** rewrite the paragraph to describe the actual
   mechanism (RNGkind pinned to L'Ecuyer-CMRG in
   `analysis/scripts/simulation.R`; master seed 20260306 consumed
   once inside `create_scenario_grid()` to draw one
   `sample.int()`-based seed per scenario-replicate; each replicate's
   seed consumed once by `set.seed()` inside
   `generate_lmm_data()`; `furrr` parallel execution with
   `seed = NULL` because seeding is handled explicitly upstream).

3. **The "Morris et al. (2019) ADEMP Compliance" section
   reproduces a stale audit and now misstates the code's compliance
   status.** Location: `report.Rmd`, final section (lines 787-802),
   quoting `docs/morris-audit-2026-04-17.md`. The manuscript lists as
   open gaps: "`n_sim = 500` not documented with an explicit Monte
   Carlo SE justification" and "`RNGkind('L'Ecuyer-CMRG')` not
   pinned." **Verified by inspection** of the current
   `analysis/scripts/simulation.R`: lines 24-27 contain an explicit
   MCSE-based justification for `n_sim = 500` ("for bias MCSE <= 0.002
   at empirical SE ~ 0.04, n_sim >= 400 ... n_sim = 500 gives bias
   MCSE approximately 0.0018"), and line 15 pins
   `RNGkind("L'Ecuyer-CMRG")` before any seeding. Both of these gaps
   are therefore already closed in the code as it stands, but the
   manuscript still tells the reader they are open. Only the third
   listed gap (no post-run `.Random.seed` capture, no coverage
   metric) remains accurate on inspection of
   `R/performance_metrics.R`, which has no coverage function and no
   RNG-state capture. A referee would read this as evidence that the
   manuscript's own self-audit was not re-run against the code that
   generated the reported numbers, undermining confidence in the
   rest of the reproducibility claims. **Remediation:** re-run the
   ADEMP self-audit against the current code before the next
   submission draft, update or re-date the audit file, and correct
   the in-manuscript summary to reflect only genuinely open gaps
   (RNG-state capture and coverage as a performance measure).

4. **The random-slope target parameter ($\tau_1 = 0.5\,\tau_0$) is
   an undisclosed, seemingly arbitrary modeling choice that
   determines the true conditional $R^2$ and the random-slope
   results, but it is never stated, justified, or varied in the
   manuscript.** Location: `R/math_utilities.R::solve_dgp_params()`
   (line 57, `tau1 <- tau0 * 0.5`) vs. `report.Rmd` "Data-Generating
   Mechanisms" (lines 383-402) and "Estimands" (lines 438-446),
   neither of which mentions how $\tau_1$ is fixed relative to
   $\tau_0$. **Inspected**: the manuscript's DGP equation includes
   $b_{1i} \sim N(0,\tau_1^2)$ as a free quantity but the reader is
   never told that $\tau_1$ is pinned at exactly half of $\tau_0$ in
   every random-slope scenario, nor is any rationale given (e.g., a
   targeted slope-level ICC, or a targeted proportion of
   conditional-vs-marginal $R^2$ attributable to the slope). Because
   this ratio directly sets `var_random = tau0_sq + tau1^2`, which
   feeds `true_r2c`, every random-slope result in Tables
   \ref{tab:bias-marginal}, \ref{tab:mse-table}, and
   \ref{tab:bias-conditional} depends on a hidden, single-point
   choice that the manuscript presents as if it followed
   mechanically from ICC and target $R^2_m$ alone. A referee
   evaluating whether the random-slope conclusions ("the Johnson
   extension showed modestly lower bias on theoretical grounds") are
   robust cannot do so without knowing this was fixed at one
   arbitrary value and never varied factorially. **Remediation:**
   state the $\tau_1 = 0.5\,\tau_0$ convention explicitly in the DGP
   section with a rationale, and either (a) add sensitivity
   scenarios varying the slope-to-intercept variance ratio, or (b)
   explicitly scope the random-slope conclusions as conditional on
   this one ratio.

5. **The literature-review claim that "no systematic simulation
   study has compared their statistical properties" is asserted
   twice (Abstract, Introduction) without engagement with several
   directly relevant citations that already appear in the project's
   own bibliography but are never cited in the text.** Location:
   `report.Rmd` Abstract (lines 63-66) and Introduction (lines
   132-135); `analysis/report/references.bib` contains
   `piephoCoefficientDeterminationR22019`,
   `stoffelPartR2Partitioning2021`,
   `snijdersMultilevelAnalysis2012`, `raudenbushHLM2002`, and
   `burtonDesignAnalysisMonteCarlo2006`, none of which is cited
   anywhere in `report.Rmd` (**verified** by cross-referencing all
   `@citekey` occurrences in the Rmd against `\begin{...}` entries in
   the bib file: zero matches for these five keys). Stoffel et al.
   (2021, `partR2`) in particular is a semi-partial $R^2$/variance-
   partitioning package for mixed models that postdates and directly
   engages the Nakagawa-Schielzeth/Johnson framework, and Piepho
   (2019) is a methodological commentary specifically on the
   coefficient of determination for mixed models — both are squarely
   on-topic for a novelty claim of this kind. Their presence in the
   `.bib` file but absence from the text suggests either an
   incomplete literature review or leftover entries from an earlier
   draft; either way, a referee cannot currently verify the gap claim
   from the manuscript as written. **Remediation:** either integrate
   these sources into the literature review (most plausibly Stoffel
   as a seventh method / discussion point, since it is now a
   commonly used package) and adjust the novelty claim accordingly,
   or remove the unused `.bib` entries and confirm the "no systematic
   comparison" claim still holds after a literature search that
   explicitly includes packages published after 2017 (`partR2`,
   `glmm.hp`, `rsq`, `insight`).

## 3. Minor issues

1. `report.Rmd` uses `\thanks{Wertheim School of Public Health, UCSD;
   ORCID: ...}` for a single-author byline but has no separate
   "Acknowledgments" or explicit institutional affiliation block
   beyond the footnote; acceptable for many journals but worth
   confirming against the target journal's author-block
   requirements before submission.

2. Figure numbering in code comments and prose is inconsistent:
   the manuscript prose refers to "Figure 4" for the MSE/sample-size
   interaction plot (`report.Rmd` line 570), but
   `analysis/scripts/analyze_results.R` saves the corresponding
   output as `fig5_sample_icc_interaction.pdf` and does not produce
   a `fig4_*` file at all (lines 24-41). This is cosmetic but would
   confuse a reader trying to match code artifacts to manuscript
   figure numbers.

3. The true data-generating process draws the random intercept
   $b_{0i}$ and random slope $b_{1i}$ independently
   (`R/generate_data.R`, lines 24-42: separate, uncorrelated
   `rnorm()` calls), but the fitted model
   (`R/compute_r2.R::fit_lmm()`, line 26: `"(1 + x1 | cluster_id)"`)
   uses `lme4`'s default correlated-random-effects
   parameterization, estimating an intercept-slope correlation that
   is truly zero in the DGP. This is a defensible design choice
   (it reflects standard applied practice of fitting an
   unstructured `G` matrix) but is not disclosed anywhere in the
   manuscript, and it plausibly contributes to the elevated singular-
   fit rate reported for low-ICC random-slope scenarios. Worth one
   sentence of disclosure in Methods or Limitations.

4. `tests/integration/` is an empty directory (confirmed by
   directory listing) despite being documented in
   `CLAUDE.md` as containing "end-to-end pipeline tests." This is a
   repository-hygiene point rather than a manuscript defect, but it
   means the pipeline that produced `sim_results.rds` has unit-level
   coverage only (five `inst/tinytest/test-*.R` files, 270 lines
   total) and no automated check that the full driver-to-report
   pipeline reproduces expected output.

5. The Discussion (lines 674-683) states the six-method expansion
   "would increase the design to 324 scenarios with 1,000
   replications and require approximately 5-6 hours of computation
   on 8 cores." This figure is **unverified**: no benchmark or
   partial run supporting the 5-6 hour estimate is present in the
   repository, and it is not marked as a projection. Label it
   explicitly as an estimate, or remove the specific figure if it
   has not been benchmarked.

6. Style: the manuscript is generally clean US English academic
   prose; no substantive US/UK spelling violations were found.
   `CLAUDE.md`-mandated `snake_case` and native-pipe conventions are
   followed consistently in the R source.

## 4. What remains to be done

**(a) Required for correctness**

- Reconcile the Abstract's ICC/target-$R^2_m$ levels (0.5 to 0.4)
  and replicate count (1,000 to 500) with the executed design
  (Major issue 1).
- Rewrite the Reproducibility section's RNG description to match
  the actual seeding mechanism in `create_scenario_grid()` and
  `run_scenario()` (Major issue 2).
- Re-run and correct the in-manuscript ADEMP self-audit so it does
  not report already-closed gaps as open (Major issue 3).
- Disclose the $\tau_1 = 0.5\,\tau_0$ convention and its consequences
  for the random-slope estimand (Major issue 4).

**(b) Required for acceptance**

- Expand or defend the novelty claim against the uncited literature
  already in the bibliography, particularly `partR2`/Stoffel et al.
  (Major issue 5).
- Add coverage as a performance measure, or explicitly justify its
  omission, since coverage is standard for $R^2$-estimator evaluation
  per the project's own ADEMP audit.
- Disclose the correlated-vs-independent random-effects mismatch
  between DGP and fitted model, and discuss its likely contribution
  to singular fits (Minor issue 3).
- Decide, and state explicitly, whether the six-method literature
  review belongs in the main text at its current length given that
  only two of the six methods are evaluated empirically (see
  Section 5 below); at minimum, add one sentence per unevaluated
  method on why it was excluded from the empirical comparison beyond
  "future work."
- Add an integration/end-to-end pipeline test so the driver-to-report
  path has automated coverage beyond unit tests (Minor issue 4).

**(c) Desirable polish**

- Fix the Figure 4/Figure 5 labeling mismatch between prose and
  `analyze_results.R` output filenames (Minor issue 2).
- Label the 5-6 hour expansion runtime estimate explicitly as
  unverified/projected, or benchmark a partial run (Minor issue 5).
- Confirm author-block/affiliation formatting against the eventual
  target journal's house style (Minor issue 1).
- Remove or use the currently uncited `.bib` entries
  (`piephoCoefficientDeterminationR22019`,
  `snijdersMultilevelAnalysis2012`, `raudenbushHLM2002`,
  `burtonDesignAnalysisMonteCarlo2006`) once the literature-review
  scope is finalized.

## 5. Recommended framing

**Plausible framings for this paper:**

1. *New estimator/algorithm paper* — not applicable; the manuscript
   introduces no new $R^2$ definition or estimator. Both compared
   methods (Nakagawa-Schielzeth 2013; Johnson 2014) are a decade or
   more old and already implemented in widely used packages
   (`MuMIn`, `performance`). This framing is not viable and the
   manuscript does not attempt it.

2. *Computational/methods comparison paper (simulation study)* —
   the framing the manuscript currently adopts. Under this framing,
   the paper's contribution is the ADEMP-compliant Monte Carlo
   evidence itself: known-truth variance decomposition, bias/MSE/
   monotonicity under a real factorial design, and practical
   guidance. The competing literature is thin on exactly this point
   for the *two-method* comparison — Nakagawa's own papers and the
   `performance`/`MuMIn` documentation report illustrative examples
   and closed-form arguments for equivalence/non-equivalence but not
   a replicated Monte Carlo evaluation of bias, MSE, and monotonicity
   across a designed factorial grid with known ground truth. That is
   a genuine, if narrow, gap. However, the manuscript inflates the
   contribution by reviewing six methods in detail while evaluating
   only two, and by (before correction) overstating novelty relative
   to uncited but directly relevant literature (partR2, Piepho
   2019). Once the literature review is tightened (Major issue 5),
   this narrower "two-method, ADEMP-compliant" framing is honest and
   defensible.

3. *Software/tools paper* — a plausible alternative: the `mixedr2`
   package itself (analytic DGP parameterization by target ICC and
   $R^2_m$, ADEMP-structured scenario grid, MCSE-aware performance
   summaries, publication-ready `ggplot2` figures) is a reusable
   piece of infrastructure that could be framed for a venue such as
   the *R Journal* or *Journal of Statistical Software*, with the
   two-method comparison serving as the package's worked example
   rather than as the paper's main empirical claim.

4. *Pedagogical exposition* — the six-method literature review
   (Section "R-Squared Measures for Linear Mixed Models") is written
   at a level and length suitable for a tutorial/review article aimed
   at applied researchers (e.g., a *Methods in Ecology and Evolution*
   or *Journal of Educational and Behavioral Statistics* practitioner
   piece), but the manuscript's Results section is written as an
   empirical comparison, not a tutorial, creating an internal
   mismatch in register and depth.

**Recommendation.** Adopt framing 2 (computational/methods
comparison), narrowed explicitly to the Nakagawa-Schielzeth/Johnson
pair, rather than presenting the six-method landscape as the
backdrop for a study that only tests two of them. Concretely:

- *Title/abstract:* retitle to make the two-method scope explicit,
  e.g. "Bias, Precision, and Monotonicity of Marginal and Conditional
  R-Squared for Linear Mixed Models: A Monte Carlo Comparison of the
  Nakagawa-Schielzeth and Johnson Estimators," and correct the
  abstract's design parameters per Major issue 1.
- *Introduction:* keep the motivating framing (proliferation of
  $R^2$ definitions, lack of guidance) but shorten the novelty claim
  to what the simulation actually establishes — a controlled,
  known-truth comparison of the two most-used estimators — and
  explicitly cite Stoffel et al. (2021) and Piepho (2019) as adjacent
  work the paper does not attempt to displace.
- *Choice of comparators:* the current two-method scope is
  appropriate for this framing; do not expand to six methods unless
  the design and compute budget in `docs/plan-full.md` are actually
  executed. If reviewers request broader coverage, the `performance`
  package implementation (already discussed in the literature review
  as a validation check, Section "The `performance` Package
  Implementation") is the cheapest addition, since it requires no new
  DGP work, only an additional extractor comparable to
  `extract_r2_nakagawa()`/`extract_r2_johnson()`.
- *Target journal:* a mid-tier applied/methodological venue with a
  strong simulation-methodology readership is a better fit than a
  top-tier theoretical journal (JASA Theory & Methods, Biometrics)
  given that no new estimator or asymptotic theory is offered.
  *Statistics in Medicine* (whose CSL file is already used in this
  repo), *Journal of Statistical Software* (if reframed per option
  3), or an applied-methods journal in one of the target application
  fields (ecology, psychology, education) are more plausible fits
  than a top statistical-theory journal.
- *Material to de-emphasize or move to supplementary:* the detailed
  prose sub-sections for Edwards et al., Jaeger et al., and Xu — none
  of which are simulated — should be compressed to a short paragraph
  each (or a single summary table with citations) in the main text,
  with any additional detail moved to supplementary material, so the
  main text's depth of treatment matches what is actually tested.
  The `Table \ref{tab:methods-summary}` six-row summary table can
  stay in the main text as a scoping device, provided the caption and
  surrounding text make explicit that only rows 1-2 are evaluated
  here.
- *Material to emphasize:* the ADEMP design table, the MCSE-aware
  performance tables, and the monotonicity results are the paper's
  actual empirical contribution and should be foregrounded, including
  a corrected, complete Reproducibility section (Major issue 2) as a
  selling point given the venue's likely interest in simulation-study
  rigor.

## 6. Assessment

**Verdict: major revision.**

The empirical machinery (factorial ADEMP design, analytic
ground-truth parameterization, MCSE-aware performance measures, unit
tests for the core numerical functions) is sound on inspection and
represents genuine, non-trivial simulation-methodology work. However,
the manuscript as it stands contains three internally-contradictory,
verifiable factual errors in its most referee-scrutinized sections —
the Abstract's design parameters, the Reproducibility section's RNG
description, and the manuscript's own quoted ADEMP self-audit — any
one of which would draw an immediate query from a statistically
literate referee, and together they undermine confidence that the
manuscript text was checked against the code that generated the
reported numbers. Additionally, an undisclosed, unjustified,
un-varied parameter ($\tau_1 = 0.5\,\tau_0$) determines every
random-slope result, and the novelty claim is not yet reconciled with
directly relevant literature already present in the project's own
bibliography. None of these issues requires new simulation runs to
fix — they are corrections to text, disclosure, and framing — but
they are substantive enough, and numerous enough, that this cannot be
characterized as a minor-revision manuscript in its current state.

## 7. Revision history

- 2026-08-16: Initial referee-grade review. No prior
  `pub_review_whitepaper_*.md` existed in `docs/`. Identified five
  major issues (abstract/design-parameter contradiction,
  fabricated-vs-actual RNG reproducibility description, stale
  in-manuscript ADEMP self-audit, undisclosed $\tau_1$ convention,
  uncited relevant literature already in the bibliography) and six
  minor issues. Verdict: major revision.
