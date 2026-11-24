# Referee Report: Bias, Precision, and Monotonicity of Marginal and Conditional R-Squared for Linear Mixed Models
*2026-11-17 17:15 PST*

Manuscript: `analysis/report/report.Rmd` (mixedr2 workspace).
Line numbers below refer to the `.Rmd` source as reviewed.

## 1. Summary of the manuscript

The manuscript reports a Monte Carlo study, organized under the
ADEMP framework of Morris, White and Crowther (2019), of two
estimators of marginal and conditional $R^2$ for Gaussian linear
mixed models: the Nakagawa-Schielzeth (2013) estimator and the
Johnson (2014) random-slope extension. The design is a $2^5$
factorial (clusters $J$, cluster size $n$, ICC, target $R^2_m$,
random-intercept versus random-slope structure) with 500
replicates per cell and 16,000 fits in total. Performance
measures are bias, MSE, monotonicity under addition of a true
predictor, boundary violations and singular-fit rate, with Monte
Carlo standard errors. The manuscript claims that both
estimators are approximately unbiased, that they coincide for
random-intercept models, that the Johnson extension shows
modestly lower bias in random-slope models, and it recommends
the Johnson extension for random-slope models. A literature
review of six $R^2$ definitions situates the comparison.

## 2. Overall assessment and recommendation

**Recommendation: reject in current form (major revision would
not suffice without a redesign of the comparison).**

The central comparison is vacuous. In all 16,000 replicates the
two "methods" return bitwise-identical $R^2_m$ and $R^2_c$
values, including in the 16 random-slope scenarios (verified,
Major comment 1). The reason is that both are produced by the
same call, `MuMIn::r.squaredGLMM()`, whose `method` argument
selects the observation-level variance approximation for
non-Gaussian families and has no effect for a Gaussian LMM;
current MuMIn already applies Johnson's random-slope variance
formula in both calls. As a consequence, every claim of a
difference between the estimators (Abstract, Results, Discussion,
Practical Recommendation 2, Conclusions) has no support in the
data the manuscript itself produced. Several further
Results claims are contradicted by the shipped
`sim_results.rds` (Major comments 2 to 4), one of the four
stated Aims is never implemented (Major comment 5), and the
literature review mischaracterizes at least two of the methods
it describes (Major comment 6). The simulation infrastructure is
sound and reproducible, and the ADEMP reporting is better than
typical. However, the study as designed does not answer the
question its title poses. Its contribution, once corrected, is a
single-estimator evaluation of the MuMIn implementation. A
prior simulation of the same kind (LaHuis et al., 2014) already
exists, and the field has since moved to the Rights and Sterba
(2019) integrative framework. The work in its present form fits
a software-note or teaching venue rather than a top-tier
statistics journal.

## 3. Significance and novelty

The manuscript's novelty claim (lines 151-171, Abstract lines
77-81) is that a replicated Monte Carlo evaluation of bias, MSE
and monotonicity of the Nakagawa-Schielzeth and Johnson
estimators has been lacking. Three bodies of work undercut this.

1. LaHuis, Hartman, Hakoyama and Clark (2014) report a Monte
   Carlo evaluation of several multilevel explained-variance
   measures, including the variance-of-predicted-values measure
   underlying Nakagawa-Schielzeth, across random-intercept and
   random-slope conditions. The manuscript does not cite it.
2. Rights and Sterba (2019) give an integrative framework that
   subsumes ten earlier MLM $R^2$ measures (including
   Nakagawa-Schielzeth and Johnson) as special cases, with an
   explicit treatment of random-slope variance and
   cluster-mean centering, and software (`r2mlm`). Rights and
   Sterba (2020) address $R^2$ differences for model comparison,
   which is the setting of the monotonicity aim. Neither is
   cited. A 2026 referee would regard this framework as the
   reference point for any MLM $R^2$ study.
3. Nakagawa, Johnson and Schielzeth (2017) is cited (line 238)
   only for having "unified these approaches". That paper is the
   reason the two arms here coincide, since MuMIn >= 1.41
   implements it for all fits. Its implications are not drawn.

What is genuinely new, once the identical-arms problem is
acknowledged, is a small factorial characterization of the
finite-sample bias of the MuMIn $R^2_m$/$R^2_c$ estimator, with
MCSEs. That is a useful but modest contribution. To reach a
top-tier venue the study would need (a) a real comparison
(for example MuMIn versus `performance::r2_nakagawa()` versus
`r2mlm` versus a bias-corrected or adjusted estimator), (b) a
theoretical account of the observed upward bias of $R^2_m$
(it arises because $\widehat{\mathrm{Var}}(X\hat\beta)$ includes
the sampling variance of $\hat\beta$), and (c) coverage of an
interval procedure.

## 4. Major comments

Evidence labels: **[verified]** = re-computed from
`analysis/data/derived_data/sim_results.rds` with the package's
own `summarize_all_scenarios()`; **[inspected]** = read in
source and judged; **[suspected]** = consistent with
documentation or recalled knowledge but not executed here.

**M1. The two compared estimators are numerically identical in
every replicate; all claims of a difference are unsupported.**
[verified for identity; inspected/suspected for mechanism]
`R/compute_r2.R` computes both arms with
`MuMIn::r.squaredGLMM(model)` and
`MuMIn::r.squaredGLMM(model, method = "trigamma")`. In the
shipped results, `max|nak_r2m - joh_r2m| = 0`,
`max|nak_r2c - joh_r2c| = 0`, and
`max|red_nak_r2m - red_joh_r2m| = 0` across all 16,000 rows;
`identical()` returns `TRUE`. The MuMIn documentation states
that the delta, lognormal and trigamma options govern the
observation-level variance for non-Gaussian (log-link)
families; for a Gaussian LMM the observation-level variance is
the residual variance and the option is inert. Since MuMIn 1.41
the random-slope variance follows Nakagawa et al. (2017), which
incorporates Johnson's formula in both calls. Consequently:

- Abstract lines 101-103 ("the Johnson extension showed modestly
  lower bias"), Results lines 725-727 ("The Johnson method
  occasionally showed slightly lower bias in random-slope
  scenarios"), Discussion lines 747-749, Practical
  Recommendation 2 (lines 831-833, "marginally better empirical
  performance"), and Conclusions lines 856-857 are false with
  respect to the manuscript's own output.
- Lines 99-101 and 745-747 present the identity in
  random-intercept models as an empirical confirmation of
  mathematical equivalence. It is not. Identity here is a
  property of calling the same code path twice, not evidence
  about the estimators.
- Line 544, "with the default log-normal approximation", and
  Table 1 (lines 370-377: Nakagawa-Schielzeth "Approximate" vs
  Johnson "Correct" for random slopes) misdescribe what was run.

*Remedy.* Either (a) implement the original 2013 estimator
explicitly (random-effect variance taken as $\hat\tau_0^2$ only,
ignoring slope variance), so the random-slope contrast is real,
and implement Johnson's $\overline{\mathrm{diag}}(Z\hat\Sigma Z^\top)$
formula independently as a check against MuMIn; or (b) recast
the paper as a single-estimator study and remove every
comparative claim. Option (a) preserves the title's question.
A unit test asserting that the two arms differ in at least one
random-slope replicate would have caught this.

**M2. "Approximately unbiased" overstates the bias evidence.**
[verified] The marginal-$R^2$ bias is positive in 29 of 32
cells and exceeds 2 MCSE in 15 of 32. Relative bias reaches
11.9% (scenario 17: $J=20$, $n=5$, ICC 0.10, $R^2_m=0.10$,
slope). Conditional-$R^2$ bias reaches 0.037 in the same cell,
about 18% of the true $R^2_c = 0.21$. The direction and the
dependence on $N = Jn$ are what one expects from the plug-in
estimator $\widehat{\mathrm{Var}}(X\hat\beta)$, which is biased
upward by roughly $\mathrm{tr}\{\mathrm{Var}(\hat\beta)\Sigma_x\}$.
*Remedy.* Report relative bias (listed as a measure at line 556
but never shown), state where bias is statistically and
practically non-negligible, and give the analytic explanation.
An adjusted estimator (subtracting the trace term) is a natural
and cheap comparator.

**M3. The claim that conditional $R^2$ has lower MSE than
marginal $R^2$ is contradicted by the data.** [verified] Lines
727-731 state that $R^2_c$ "was generally estimated with higher
precision, that is, lower MSE". $\mathrm{MSE}(R^2_c) <
\mathrm{MSE}(R^2_m)$ in only 9 of 32 scenarios; in all 16
cells with target $R^2_m = 0.10$ the reverse holds, often by a
factor of 2 to 7 (e.g. scenario 7: 0.00065 vs 0.00472). The
accompanying mechanism ("the random-effect variance component
... is typically the largest and most precisely estimated") is
also incorrect for this design, where $\tau_0^2 \le 0.67$ and
$\sigma^2 = 1$. *Remedy.* Replace with an accurate
description keyed to target $R^2_m$ and ICC.

**M4. The ICC-MSE interaction claim and its mechanism are not
supported.** [verified] Lines 662-667 and Abstract lines 106-108
state that higher ICC is associated with lower MSE for $R^2_m$.
Comparing ICC 0.40 with ICC 0.10 at fixed $(J, n, R^2_m,$
structure$)$, higher ICC gives lower MSE in 7 of 16 pairs,
higher MSE in 8, and is essentially tied in 1. For target
$R^2_m = 0.40$ higher ICC gives higher MSE in 6 of 8 pairs.
The proffered mechanism ("fixed-effect variance component is
estimated with greater precision when the random-effect
variance is large") has no derivation and is not consistent
with these numbers. *Remedy.* Describe the interaction as
observed (it depends on target $R^2_m$), or remove it, and
revise Discussion lines 755-759.

**M5. Aim 4 (robustness to an omitted random slope) is stated
but never implemented.** [inspected] Lines 450-452 list
robustness to fitting an intercept-only model when a slope is
present. `R/simulation.R::run_single_replicate()` always fits
the same `re_structure` used to generate the data. No result
addresses Aim 4. *Remedy.* Implement the misspecified-fit arm
(which is cheap and practically important, since omitted slopes
inflate $R^2_m$ precision claims), or delete the aim.

**M6. The literature review misdescribes at least two methods.**
[inspected/suspected; not checked against the full texts]

- *Edwards et al. (2008)*, lines 241-264. The $R^2_\beta$ of
  Edwards et al. is a Wald/Kenward-Roger $F$-based statistic,
  $R^2_\beta = (q/\nu)F / \{1 + (q/\nu)F\}$, not the likelihood
  ratio $1 - L(\beta=0)/L(\hat\beta)$ given at line 247. The
  `r2glmm::r2beta()` methods are `sgv`, `kr`, `nsj` and `lm`;
  there is no `method = "lr"` (line 255). The criticism that it
  is "sensitive to REML versus ML" therefore targets a
  different statistic.
- *Johnson (2014)*, lines 223-225. The trigamma approximation
  for the distribution-specific variance originates in Nakagawa
  et al. (2017), not Johnson (2014), whose contribution is the
  random-slope variance term. Attributing "trigamma" to Johnson
  is what led to M1.
- *Xu (2003)*, lines 290-298. Xu's principal proposal is a
  single explained-residual-variation measure
  ($\rho^2$/$\Omega^2_0$), not a level-1/level-2 pair; the
  level-specific pair is due to Snijders and Bosker (1994) and
  Raudenbush and Bryk (2002). Please re-check against the paper.
- *performance vs MuMIn*, lines 317-323. The claim that
  `performance` uses the model matrix and MuMIn the fitted values
  is unsourced and, to my knowledge, both compute
  $\mathrm{Var}(X\hat\beta)$. Possibly the authors mean a
  difference in random-slope variance handling; this should be
  verified by running both, which would also yield a real
  comparator for M1.

*Remedy.* Correct each description against the source paper
and package documentation, and add Rights and Sterba (2019) as
the organizing framework.

**M7. The monotonicity aim is weakly designed.** [verified/inspected]
The reduced model drops $x_2$, whose true coefficient equals that
of $x_1$, so the full model always adds a genuine predictor with
half the fixed-effect variance. Failures occur in only 4 of 32
cells (26 replicates of 16,000; minimum rate 0.978). The
statement that "both methods achieved near-perfect monotonicity
($> 0.95$) in scenarios with large total sample sizes and strong
fixed effects" (lines 647-650) is true of every cell and so is
uninformative. Only $R^2_m$ is tested, though Figure 3's caption
says "R-squared". The informative case is the addition of a
null or weak predictor, and $R^2_c$ monotonicity, where
variance-component re-estimation can move the denominator.
*Remedy.* Add null- and weak-predictor arms and test $R^2_c$.

**M8. The convergence rate of 100% is true by construction.**
[inspected/verified] `fit_lmm()` sets
`converged <- !is.null(model)`, and every warning (including
`lme4` convergence-gradient warnings) is muffled and stored but
never used. Line 575 reports the convergence rate as if it were
a diagnostic. *Remedy.* Classify fits with lme4 convergence
warnings separately, report their rate, and state whether they
were retained.

**M9. Practical Recommendation 4 misapplies Monte Carlo
standard errors.** [inspected] Lines 839-842 suggest MCSEs as a
measure of uncertainty for an $R^2$ estimate in an applied
analysis. An MCSE quantifies simulation error in a performance
estimate. It has no meaning for a single data set. *Remedy.*
Recommend a parametric bootstrap (as in `partR2`) or a
delta-method interval, and ideally evaluate its coverage (the
open Morris item at line 969).

## 5. Minor comments

1. Lines 735-738: boundary violations are reported as "fewer
   than 1%"; the observed rate is exactly 0 in every cell
   [verified]. Because the MuMIn estimators are ratios of
   non-negative variance estimates, violations are impossible by
   construction. Say so and drop the measure, or keep it with
   that explanation.
2. Line 554-563: relative bias and empirical variance/SE are
   listed as reported measures but appear in no table or figure.
3. Line 851-852: "the first systematic comparison" contradicts
   the narrowed novelty claim at lines 77-81 and 151-166 and is
   untrue in light of LaHuis et al. (2014).
4. Lines 406-408: "jointly account for the vast majority of $R^2$
   values published for LMMs" needs a citation or a bibliometric
   count; lines 142-144 ("required or strongly encouraged by many
   journals") likewise.
5. Lines 467-473 and Table 2: in slope scenarios "ICC" is
   $\tau_0^2/(\tau_0^2+\sigma^2)$, the intraclass correlation at
   $x_1 = 0$ only. State this; the effective clustering is larger.
6. Lines 636-639: the right skew noted for small-sample
   random-slope cells is equally present in the small-sample
   intercept-only cell (sample skewness 0.59 in scenario 1 vs
   0.66 in scenario 17) [verified]; attribute it to sample size,
   not to slopes.
7. Lines 589, 632, 647, 661: figures are referenced by hard-coded
   number ("Figure 1") rather than `\@ref(fig:...)`.
8. Displayed equations are unnumbered (`$$`), which prevents
   cross-reference and makes review anchoring harder.
9. Line 938: the "Morris et al. (2019) ADEMP Compliance" section
   sits under the "References" heading; the bibliography will be
   placed after it. Move it to an appendix and use a
   `<div id="refs">` placement.
10. Line 6 (YAML): `date: Sys.Date()` makes the manuscript
    date drift on every render; fix the date for submission.
11. `references.bib`: `raudenbushHLM2002` is typed `@article`
    with a publisher and no journal; it should be `@book`.
12. Lines 958-959: the $n_{sim}$ justification assumes empirical
    SE about 0.04; observed empirical SE for $R^2_m$ ranges from
    0.016 to 0.079 [verified], so the largest bias MCSE is
    about 0.0035, not 0.0018. Restate the justification against
    the worst cell.
13. Lines 873-874: "openly available" should name the repository
    URL (`github.com/rgt47/mixedr2`) and an archival DOI.
14. Line 776: the 5 to 6 hour projection for 324 scenarios is
    not needed in a journal article.
15. Lines 788-799: the correlated-$G$ versus independent-DGP
    mismatch is well disclosed; it would be straightforward to
    add the `(1 + x1 || cluster_id)` fit as a sensitivity arm.

## 6. Missing and questionable references

| Claim location | Issue | Suggested source |
|---|---|---|
| Lines 151-171, novelty | Prior Monte Carlo study of MLM $R^2$ measures omitted | LaHuis DM, Hartman MJ, Hakoyama S, Clark PC. Explained variance measures for multilevel models. *Organizational Research Methods* 2014;17(4):433-451. doi:10.1177/1094428114541701 |
| Lines 173-343, review | Integrative framework subsuming NS and Johnson omitted | Rights JD, Sterba SK. Quantifying explained variance in multilevel models: an integrative framework for defining R-squared measures. *Psychological Methods* 2019;24(3):309-338. doi:10.1037/met0000184 |
| Lines 447-448, monotonicity aim | $R^2$ differences for nested model comparison | Rights JD, Sterba SK. New recommendations on the use of R-squared differences in multilevel model comparisons. *Multivariate Behavioral Research* 2020;55(4):568-599. doi:10.1080/00273171.2019.1660605 |
| Lines 241-255, Edwards | Formula and `method = "lr"` do not match source or package | Edwards et al. 2008 (already cited), eq. for $R^2_\beta$; `r2glmm` reference manual (methods `sgv`, `kr`, `nsj`, `lm`) |
| Lines 223-229, Johnson | Trigamma attributed to Johnson | Nakagawa, Johnson, Schielzeth 2017 (already cited) |
| Lines 406-408 | "vast majority" claim uncited | A bibliometric source or remove |
| Lines 142-144 | Journal reporting requirements uncited | e.g. APA Publication Manual (7th ed.) or a specific guideline |
| `references.bib` | `raudenbushHLM2002` mistyped | Change to `@book` |

Searches run: LaHuis 2014 MLM explained-variance simulation;
Rights and Sterba 2019 integrative $R^2$ framework (and the 2020
and 2021 follow-ups surfaced in results); `r2glmm::r2beta`
method options; MuMIn `r.squaredGLMM` method semantics. I did
not search PubMed, nor for post-2021 Bayesian $R^2$ work for
mixed models (e.g. Gelman et al. 2019, Bayesian $R^2$), which a
referee may also expect to see mentioned.

## 7. Suggestions for strengthening the paper

1. Make the comparison real: original 2013 NS (intercept
   variance only), Johnson via an independent implementation,
   `performance::r2_nakagawa()`, `r2mlm` (Rights-Sterba), and a
   bias-adjusted $R^2_m$.
2. Derive the leading-order bias of $\widehat{R}^2_m$ and
   overlay it on Figure 1.
3. Implement Aim 4 and the independent-$G$ fitted model.
4. Add a parametric-bootstrap interval and report coverage.
5. Vary $\tau_1/\tau_0$ (already acknowledged, lines 491-493).
6. Add a regression test asserting that the two estimator arms
   differ in random-slope fits.

## 8. Scope of this review

- **Verified (executed):** loaded `sim_results.rds` (16,000
  rows, 0 NA), re-ran `summarize_all_scenarios()` from
  `R/performance_metrics.R`, and computed estimator identity,
  bias/MCSE ratios, relative bias, $R^2_c$ vs $R^2_m$ MSE,
  ICC-MSE pairs, monotonicity failures, boundary violations,
  singular rates by cell, and skewness for the Figure 2 cells.
- **Inspected:** `R/compute_r2.R`, `R/generate_data.R`,
  `R/math_utilities.R`, `R/simulation.R`,
  `R/performance_metrics.R`, `references.bib`, the prior
  remediation log. The DGP truth formulas are correct for
  $x \sim N(0,1)$ independent predictors.
- **Not checked:** I could not re-fit models because `MuMIn` and
  `furrr` are not installed in the local R library; the MuMIn
  mechanism in M1 rests on its documentation, while the identity
  itself is verified. I did not render the manuscript, inspect
  figure output, or read the full texts of Edwards et al.
  (2008), Xu (2003) or LaHuis et al. (2014); M6 items are
  therefore marked inspected/suspected.
