# Voice Revision Log: report.Rmd
*2026-11-17 17:15 PST*

Prose in `analysis/report/report.Rmd` was revised into the voice
defined in `~/.claude/commands/use_rgtvoice.md`. The stricter
sentence rule ('2. Short, simple sentences': one idea per sentence,
target 15 to 20 words, ceiling 25, subordinate clauses split with a
plain connective, common words preferred) was applied to every
edited passage. About 40 prose passages were edited, from the
Introduction through the ADEMP compliance section. Changes are
left uncommitted in the working tree.

## Kinds of changes made

- Long sentences split at clause boundaries, with plain connectives
  at the head of the second sentence ('That is,', 'As a result,',
  'However,', 'This means').
- Signposting added: an opening rhetorical question in the
  Introduction and in 'R-Squared Measures for Linear Mixed Models'
  ('But what counts as explained variance?'), 'In this section we
  shall', 'In symbols,' and 'That is,' before displayed equations.
- Trade-off framing ('On the plus side ... On the minus side') in
  the Nakagawa-Schielzeth and Edwards et al. subsections, replacing
  'strengths ... limitations' constructions.
- Signature words used sparingly for stated limitations
  ('Unfortunately,' three times: competing measures, the unvaried
  $\tau_1/\tau_0$ ratio, the unbenchmarked runtime; and for the
  missing Xu package).
- Simpler diction: 'needs' for 'requires', 'about' for
  'approximately', 'main' for 'primary', 'shows' for 'displays'.
- `where ...` definitions after the first equation split into
  separate sentences.
- 'Based on these results' changed to 'On the basis of these
  results'; 'will be taken up' to 'We shall take it up'.

## Passages deliberately left alone

- **Abstract**: excluded by the skill (genre convention).
- **YAML header, all code chunks and chunk options, inline R
  expressions, displayed equations, citation keys, cross-references,
  table and figure content, section headings**: excluded by the task
  constraints.
- **Performance-measure bullet list** (Simulation Design): terse
  definitional entries, not prose.
- **Conflict of interest, Funding**: one-line boilerplate.
- **Morris audit 'Gaps closed' bullets**: these carry exact numbers
  and file paths; splitting them added no clarity.
- **Substantive claims**: kept verbatim in meaning even where the
  referee report (`referee-report-2026-11-17.md`) finds them
  unsupported or false. Examples are the Johnson-versus-NS
  difference claims, 'approximately unbiased', the ICC-MSE and
  conditional-versus-marginal MSE claims, 'fewer than 1%'
  boundary violations, 'first systematic comparison', and the
  Edwards `method = "lr"` description. Fixing these is a separate
  decision for the author.

## Notes

- A handful of sentences still run to about 25 to 28 words because
  they contain a citation key, a code path or an inline math
  expression that cannot be split cleanly.
- No em dashes were introduced (the file contains none). Spelling
  is US throughout.
- The manuscript was not rendered after editing, so the LaTeX
  build was not checked; only prose lines outside chunks and math
  were touched (confirmed by inspecting the `git diff` hunks).
