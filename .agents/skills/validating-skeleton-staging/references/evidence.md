# Evidence gates

Choose evidence from the change's expected behavior. Generic health signals support a
behavioral proof but do not replace it.

## Strength of evidence

Prefer, in order:

1. Server-side or downstream observation of the changed semantic.
2. Client outcome metric tied to the changed operation and status.
3. Successful application result that cannot occur without the changed path.
4. Targeted logs showing the expected branch or result.
5. General liveness or absence of errors.

If only levels 4–5 are available, call the result indirect.

Examples:

| Change class | Positive proof | Regression signals |
| --- | --- | --- |
| TLS, identity, or auth | Server sees the expected authenticated identity on the exact RPC | Handshake, certificate, SDS, transport, unauthenticated, or permission errors |
| Client routing or endpoint | Target server receives the expected method from the expected client; client success status | Connection, DNS, routing, target-resolution, or wrong-backend errors |
| Retry or timeout | Outcome/latency under an observed qualifying failure | Timeout growth, request amplification, stuck work, or duplicate effects |
| Assignment/rebalance | Assignments converge and processing continues | Rebalance loops, zombies, missed fetches, stalled partitions |
| Consumer path | Fetched/pulled/committed traffic and bounded time lag | Fetch failures, lag growth, buffer saturation, missed fetches |
| Producer path | Successful writes and downstream traffic | Write failures by type, queue saturation, unavailable metadata |
| Config resolution | Expected resolved value or downstream operation using it | Resolution failures, fallback changes, stale configuration |
| Filter/serialization | Expected processed/output counts or payload property | Decode, encode, filter, or schema errors; count divergence |
| Performance/resource | Stable throughput and latency at comparable load | CPU, memory, throttling, latency, or restart regression |

A normal staging run cannot prove a failure-only behavior if the triggering condition
never occurs. Report that limitation instead of manufacturing a pass.

For gRPC authentication, routing, or client changes, trace the exact fully qualified RPC
method and target service from source. Discover the actual metric tag casing/values
before querying. Prefer `grpc.dd.server.client_identity` grouped by authentication type,
client service, namespace, datacenter, target service, and method when available. A
server-observed identity is direct proof for that method only; no series is unobserved,
not unauthenticated.

## Baseline health

Select only metrics relevant to the exercised release role. Common candidates include:

- `libstreaming.stream_consumer.alive`
- `libstreaming.stream_producer.alive`
- `libstreaming.stream_consumer.fetched_bytes`
- `libstreaming.stream_consumer.pulled_messages`
- `libstreaming.stream_consumer.commits`
- `libstreaming.stream_consumer.missed_fetch`
- `libstreaming.stream_producer.writes.success`
- `libstreaming.stream_producer.writes.failures`
- `streaming.topicstats.time_lag.max_by_worker`
- `kubernetes_state.deployment.replicas_unavailable`
- `kubernetes.containers.restarts`

Discover current metric names and tags before relying on them. Filter by exact matching
version and release when the metric carries those tags. When it does not, correlate the
release with deployment evidence and label the conclusion inferential.

Keep every Pup query on the exact staging domain returned by deployment discovery. The
staging domains can represent different organizations and must not be mixed in one
comparison.

For gauges such as `alive`, report the aggregation and whether the conclusion is only
point-in-time. For counts, report the window and absolute count; for rates, state the
normalization. Do not describe a count change as a rate change.

## Pre/post comparison

- Use equal fixed UTC windows around the actual rollout, not branch integration.
- Exclude the transition interval and filter each window to the relevant old or new
  version.
- Compare traffic volume before comparing raw error counts. Prefer error rate when
  request volume changes materially.
- Query a recent current window to detect delayed problems.
- Break aggregates down by release before attributing a regression. Experimental
  loadgens commonly dominate fleet-wide error totals.
- Check whether the same symptom exists on prior artifacts or workload revisions and
  unaffected controls.

## Logs

Build targeted queries from error strings and contexts in the changed code. Search both:

1. exact operation/client errors introduced or handled by the change;
2. the surrounding failure class, such as TLS, transport, timeout, rebalance, Kafka,
   serialization, or configuration.

Separate rollout-startup transients from sustained failures. Preserve timestamps,
versions, releases, and error classifications. An application-level `not found` result
can prove transport success while still representing an unhealthy test configuration;
state both facts.

## Rollout health

When direct Kubernetes access is available, verify desired, updated, ready, and
available replicas; current image/version; pod creation times and restarts; and whether
old ReplicaSets still serve traffic.

When using Kubernetes-state metrics instead, check unavailable replicas and restart
deltas for exact releases and versions. This does not prove old ReplicaSets are drained,
so keep that limitation in the report.

No data is not zero. Widen the window, validate tag spelling, and then mark the gate
unvalidated if the signal remains absent.
