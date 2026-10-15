---
name: validating-skeleton-staging
description: Validates post-rollout dd-source changes expected to execute in managed streaming-staging skeletons. Use when given a PR, commit, or range and asked to prove staging integration, affected Rust/Java/Go deployment coverage, expected runtime behavior, and absence of attributable regressions.
---

# Validating skeleton staging

Validate a change against the managed `streams-skeleton-rust`,
`streams-skeleton-java`, and `streams-skeleton-go` staging deployments. Produce an
evidence-backed verdict, including explicit coverage gaps.

This is a read-only workflow. Do not reset the integration branch, trigger Conductor,
restart workloads, change feature flags, add kube contexts, or mutate resources unless
the user separately authorizes that action.

## Inputs

Require a PR URL, commit, or commit range. Infer the repository, affected bindings,
staging integration commit, rollout time, and validation signals when possible. Ask
only when the change's intended runtime behavior cannot be recovered from the diff,
thread, PR, tests, or code.

Default to commercial staging. Treat staging-fed and GovCloud as separate targets
unless the user includes them.

## Build the validation contract

Before querying staging:

1. Resolve the exact change and intended behavior from the diff, PR, tests, and linked
   context. Do not validate only the commit subject.
2. Trace changed code through current BUILD files and application configuration to
   identify affected skeleton implementations and executable paths. Read
   [references/scope.md](references/scope.md).
3. For every changed runtime surface, record:
   - expected behavior;
   - condition that exercises it;
   - affected binding and candidate release;
   - strongest positive runtime signal;
   - regression signals;
   - whether skeleton staging can exercise it at all.
4. Mark compile-only, conditional, unused, and unobservable paths now. An image that
   contains code does not prove that the code ran.

Use the validation contract to drive queries. Do not apply a fixed metric checklist
without tying each signal to the change.

## Prove integration and rollout

1. Verify the exact change is an ancestor of `streaming-staging`, or identify the
   integration commit that contains it. Record the integration time. Refresh remote
   refs without changing HEAD, the index, or the worktree when ordinary read-only
   repository metadata updates are allowed. If the user forbids any repository
   mutation, use a temporary bare/blobless clone or the GitHub API and pass `--no-fetch`
   to deployment discovery. Never rely on a stale local ref.
2. Confirm from current repository configuration that the affected skeleton service is
   sourced from `streaming-staging`. Branch integration is not deployment proof.
3. Choose provenance evidence that matches the shipped artifact:
   - For libstreaming changes, use the
     `streaming-platform-operators:finding-libstreaming-deployments` skill with
     `--env staging --json`. For a final safety verdict, use `--no-age-prefilter` or
     preserve age-prefiltered negatives as heuristic rather than ancestry-proven.
   - For skeleton application changes, prove the running image revision through build
     or deploy metadata and the observed image digest/version.
   - For chart or deploy-only changes, prove the rendered resource contains the change
     and that the corresponding workload revision is serving.
   Do not use libstreaming version ancestry as proof for an app- or chart-only change.
   Mark provenance unvalidated if the appropriate evidence is unavailable.
4. Start with a historical lookback such as 24 hours and a current lookback such as 10
   minutes; widen the current window for low-traffic releases.
5. Derive the expected managed release inventory from each current `k8s/deploy.ts` and
   values configuration. Compare expected releases with observed rows. Keep these
   categories separate:
   - matching artifact or workload revision;
   - non-matching artifact or workload revision;
   - unresolved version;
   - expected release with no telemetry;
   - observed manual, experiment, or stale release outside the managed inventory.
6. Preserve `00000000` and other unknown versions as unresolved. Do not count missing
   telemetry as successful rollout.

Represent the managed inventory as exact `(datacenter, service, release)` tuples from
the deploy generator, including its release-prefix construction and target selection.
Join telemetry on those dimensions. Rows outside that tuple set are unmanaged even if
their names look similar; expected tuples absent from telemetry are missing. Do not use
substring or release-name heuristics as the denominator.

The deployment finder is a recent-telemetry snapshot, not rollout history. Report its
environment, domain, lookback, generated time, and local fetch status. Use the returned
domain for every subsequent Pup query; do not mix staging organizations. When a shared
Rust change affects Go, separate the Rust-backed DLGO releases from the standalone Go
control cohort.

## Establish comparison windows

Locate the first stable matching version or container revision and last prior revision
for each affected runtime, release, and datacenter. Use those observations—not branch
integration time or query generation time—as rollout anchors. Staggered cohorts need
separate anchors. Use fixed, equal pre/post windows filtered to exact versions and
releases. Exclude the rollout transition (normally at least 15 minutes). Also query a
recent current window.

Prefer two-hour windows when traffic permits. Widen both sides equally for sparse
signals. State all UTC boundaries. Never compare a mixed-version window with a
single-version window.

## Validate behavior and regressions

Read [references/evidence.md](references/evidence.md), then collect:

1. At least one direct positive proof of the intended behavior per distinct runtime or
   packaging path.
2. Producer and/or consumer liveness and sustained data flow for every release used as
   behavioral evidence.
3. Equal-window failure, lag, restart, readiness, and change-specific error signals.
4. Targeted logs for errors introduced or handled by the changed code, plus the
   relevant broader failure class.
5. A control or historical comparison when an unhealthy signal exists.

Use the `pup` skill for staging metrics and logs. Use
`streaming-platform-operators:stream-consumer-diagnosis` only when a consumer regression
requires deeper read-only diagnosis; do not execute its remediation suggestions without
fresh authorization. Direct Kubernetes inspection is useful for rollout convergence,
but Kubernetes-state metrics are acceptable indirect evidence when kube authentication
is unavailable; label them as indirect.

Attribute regressions, do not merely enumerate them. Determine whether a symptom:

- began after the matching artifact or workload revision arrived;
- is confined to matching artifacts or workload revisions;
- also occurs on prior artifacts, workload revisions, or unaffected controls;
- is an application failure, dependency failure, or transport/runtime failure;
- is a count, rate, gauge, or point-in-time observation.

Do not turn “pre-existing” into “healthy.” Report ongoing unrelated failures separately.

## Authentication discipline

Run one credential preflight at a time. Do not start parallel OAuth or Kubernetes
device flows. If interactive authentication is required, stop and ask the user to
complete it, then retry serially. Never repeat tokens, device codes, or callback URLs.
Do not terminate an unrelated authentication process without permission; clean up only
processes started by this validation.

## Verdict

Read [references/reporting.md](references/reporting.md) before answering.

- **Pass:** all in-scope managed releases are on matching artifacts or workload
  revisions, each runtime path has direct positive proof, health gates pass, and no
  attributable regression is found.
- **Partial pass:** at least one intended runtime path has direct positive proof and no
  attributable regression, but rollout or other path coverage is incomplete.
- **Fail:** the expected behavior is contradicted or an attributable regression is
  found.
- **Not applicable:** no managed skeleton can execute the changed path.
- **Not validated:** an in-scope path is executable and evidence collection completed,
  but the available observations are insufficient to establish execution and health.
- **Blocked:** an in-scope path is executable, but required access or telemetry could
  not be collected and no safe alternative can answer the question.

Apply `not applicable` before `blocked`, and `blocked` before `not validated`.

Never claim fleet-wide safety from one healthy release, direct behavior from liveness
alone, or “no regressions” from an unversioned current snapshot.
