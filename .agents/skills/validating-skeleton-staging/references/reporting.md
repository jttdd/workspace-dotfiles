# Reporting

Lead with the overall verdict and its scope. A concise report must still preserve
non-matches, unresolved versions, missing telemetry, unexercised paths, and ongoing
unrelated failures.

## Required sections

### Verdict

Use `pass`, `partial pass`, `fail`, `not applicable`, `not validated`, or `blocked`.
State exactly what is proven, for example: “The observed Rust-to-Slicer path is using
mTLS, with no attributable regression in the checked signals.”

Avoid “working everywhere” or “no regressions” when evidence covers only one method,
release, datacenter, short window, or indirect signal.

### Provenance and rollout

Report:

- requested change and integration commit;
- integration branch and integration time;
- affected runtime/binding;
- deployment query generated time and lookback;
- managed-release denominator;
- matching, non-matching, unresolved, and missing artifact/revision counts;
- exact names for non-matching and missing managed releases;
- repository fetch performed by the deployment finder.

### Behavior and health

Report three independent top-level gates before the per-path table:

- **Coverage:** complete, incomplete, or unknown, based on matching, non-matching,
  unresolved, and missing managed releases.
- **Execution:** confirmed, indirect, unobserved, or not applicable for each changed
  runtime path.
- **Health:** no regression observed, regression, or indeterminate for the compared
  signals and windows.

For each validation-contract row, report:

| Runtime path | Evidence | Window | Status |
| --- | --- | --- | --- |

Use `pass`, `fail`, `indirect`, or `not validated`. Include quantities and units.

### Regressions and limitations

State:

- which health gates were compared before and after;
- any detected issue and whether it is attributable;
- ongoing pre-existing or unrelated failures;
- paths not exercised or directly observable;
- blocked cluster, credential, or telemetry coverage;
- whether a rollout or enforcement hold should remain.

## Decision rules

- A matching artifact plus liveness is deployment evidence, not direct behavioral proof.
- A direct proof from one runtime does not validate another packaging path.
- An unhealthy symptom that predates the rollout is not attributable, but it remains an
  operational issue.
- An unresolved version is not a non-match.
- An expected release absent from telemetry is not deployed by default.
- If any required managed release is old, unresolved, or missing, the fleet-wide verdict
  cannot be `pass`.
- Use `partial pass` only when at least one intended path has direct behavioral proof
  and adequate health evidence. Rollout ancestry without execution proof is `not
  validated`, not a partial pass.
- Age-prefiltered negatives are heuristics. Use ancestry-checked negatives for a final
  safety verdict or state the limitation.
- If a changed path has no staging exercise, say so explicitly and recommend the
  smallest additional validation that would close the gap.
