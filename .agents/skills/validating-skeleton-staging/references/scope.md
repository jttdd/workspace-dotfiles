# Scope classification

Derive scope from the current dependency graph and deploy configuration. These mappings
are starting points, not substitutes for reading the changed BUILD targets and callers.

## Runtime mappings

| Changed surface | Candidate skeleton scope | Required verification |
| --- | --- | --- |
| Shared libstreaming Rust core | Rust, Java JNI, Go DLGO | Confirm each application still embeds the changed Rust target. |
| Rust binding or Rust skeleton | Rust | Check whether the change is core, binding-only, or app-only. |
| Java wrapper/JNI API | Java | Determine whether the native Rust implementation also changed. |
| Go DLGO wrapper | Go DLGO | Do not group with standalone Go. |
| Standalone Go libstreaming | Plain Go | Treat DLGO as a separate implementation or control. |
| Skeleton application code | That application and configured releases | Classify releases by the code path they enable. |
| Shared chart, image, or deploy config | Every rendered consumer of that target | Trace select/render logic rather than guessing from names. |
| Service client library outside libstreaming | Skeletons with a proven reverse dependency | A directory name alone is not dependency evidence. |

The Go skeleton builds two binaries: the default wrapper embeds standalone Go, while
the DLGO wrapper embeds the Rust-backed DLGO library. The Java skeleton packages the
JNI library. Re-check these facts in current BUILD files because bindings can migrate.

## Route provenance by artifact

| Artifact carrying the change | Provenance evidence |
| --- | --- |
| Libstreaming library | `streaming-platform-operators:finding-libstreaming-deployments` ancestry verdict |
| Skeleton application image | Build/deploy source revision joined to the running image digest or version |
| Chart or deploy configuration | Rendered live resource/revision containing the changed value or structure |
| Shared dependency bundled into an image | Build graph plus image source revision; use libstreaming ancestry only if the changed artifact is libstreaming |

Branch ancestry proves eligibility to build, not that a resulting artifact is serving.
The deployment finder reports recent libstreaming telemetry, not app-image or chart
history.

## Discover affected code paths

1. Inspect the diff and changed targets.
2. Search scoped BUILD files for direct and transitive consumers. Use Bazel query only
   when it can answer the dependency question precisely and cheaply.
3. Follow configuration branches, feature flags, endpoint selection, and defaults that
   determine whether a skeleton invokes the path.
4. Inspect skeleton values files to select releases that actually exercise it:
   producer/loadgen, consumer, mixed, sharded, weak-locality, filtering, dynamic config,
   or another relevant profile.
5. If no managed release enables the path, mark it `not exercised`; do not pick a
   merely convenient release.

## Establish the managed inventory

Use current source-of-truth files, especially:

- `domains/streaming/staging.datadog.yml` for integration-branch redeploy behavior;
- each skeleton's `k8s/service.datadog.yaml` for branch, schedule, and target;
- each skeleton's `k8s/deploy.ts` for generated releases and datacenters;
- common and per-release values for runtime mode and exercised behavior.

Do not hardcode a release count in the skill. Inventory changes over time.

Separate:

- commercial `staging` targets sourced from `streaming-staging`;
- staging-fed, GovCloud, DR, or prod targets sourced from another branch;
- generated managed releases;
- personal, fleet, experiment, and stale releases still emitting telemetry.

The expected denominator comes from current managed configuration, not the number of
metric series returned.

## Coverage matrix

Create one row per changed runtime surface:

| Surface | Binding/runtime | Exercise condition | Candidate release | Positive proof | Regression proof | Coverage |
| --- | --- | --- | --- | --- | --- | --- |

Use `direct`, `indirect`, `not exercised`, or `unobservable` for Coverage. If no managed
skeleton can execute any changed path, the validation is `not applicable`. Distinct
packaging paths need distinct rows even when they share source code.
