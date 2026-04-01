---
name: streaming-admin
description: Interact with the streaming-admin gRPC APIs using grpcurl to manage streams, consumer groups, backfills, topics, and Kafka clusters in the Streaming Platform. Use this when the user wants to query, create, update, or manage streaming resources (streams, consumer groups, backfills, clusters and topics, etc...).
---

# streaming-admin

## Overview

The streaming-admin service is defined in `$HOME/dd/logs-backend/domains/streaming/apps/streaming-admin`.

It manages streams, consumer groups, backfills, topics, Kafka clusters and their lifecycles and definitions.
It exposes all operations with gRPC.

### Deployment Architecture

There is **one deployment per**:
- **Datacenter** (dc): `us1`, `eu1`, `ap1`, etc.
- **Environment** (env): `staging`, `prod`
- **Streaming instance**: `metrics`, `evp`, `shared`, `test`

## Connection Details

### gRPC API URL Structure

```
streaming-admin-{instance}.{dc}.{env}.dog:443
```

Examples:
- `streaming-admin-metrics.us3.prod.dog:443`
- `streaming-admin-evp.eu1.staging.dog:443`

### Admin UI (Web Interface)

The streaming-admin service also provides a web-based Admin UI for querying lag, topics, streams, and other information. The Admin UI is deployed as a static-app.

**URL Structure:**
```
https://streaming-admin.static-app.{host_dc}.{env}.dog/?datacenter={target_dc}.{env}.dog&streamingInstance={instance}
```

**Parameters:**
- `host_dc`: The datacenter hosting the Admin UI (typically `us1`)
- `target_dc`: The datacenter you want to query (e.g., `ap1`, `eu1`, `us3`)
- `env`: Environment (`prod` or `staging`)
- `instance`: Streaming instance (`metrics`, `evp`, `shared`, `test`)

**Examples:**
- Query ap1 prod EVP: `https://streaming-admin.static-app.us1.prod.dog/?datacenter=ap1.prod.dog&streamingInstance=evp`
- Query eu1 prod metrics: `https://streaming-admin.static-app.us1.prod.dog/?datacenter=eu1.prod.dog&streamingInstance=metrics`
- Query us3 staging shared: `https://streaming-admin.static-app.us1.staging.dog/?datacenter=us3.staging.dog&streamingInstance=shared`

**Note:** The Admin UI provides a convenient way to query streaming-admin directly without using grpcurl. This is particularly useful during incidents when you need quick visibility into consumer lag across streams.

### Required Header

All requests require the following header:
```
X-datadog-target-release: streaming-admin-{instance}.streaming
```
Examples:
- `X-datadog-target-release: streaming-admin-metrics.streaming`
- `X-datadog-target-release: streaming-admin-evp.streaming`

## Instructions

### 1. Gather Required Parameters

Before making any grpcurl call, ensure you have:

- **dc** (datacenter): e.g., `us1`, `eu1`, `ap1`
- **env** (environment): `staging` or `prod`
- **instance**: `metrics`, `evp`, `shared`, or `test`

**If any parameter is missing**, ask the user to provide it using the AskUserQuestion tool with clear options.

Example question format:
```
"Which streaming instance do you want to interact with?"
Options: metrics, evp, shared, test
```

### 2. Get latest commands definitions

- proto files are located in: `$HOME/dd/logs-backend/libs/grpc/streaming-admin/src/main/resources/streaming/admin/`
- Main services are:
  - `streamingadmingrpc.StreamingAdminSystem` - Query and management operations
  - `streamingadmingrpc.StreamOperations` - Stream lifecycle and configuration operations

Ideally, get latest definitions from the origin's prod branch. If you can't use the local version.

### 3. Construct grpcurl Commands

Use the following pattern for grpcurl commands:

```bash
grpcurl \
  -H "X-datadog-target-release: streaming-admin-{instance}.streaming" \
  -d '{json_payload}' \
  streaming-admin-{instance}.{dc}.{env}.dog:443 \
  {service_package}/{rpc_method}
```

### 4. Show Command Before Execution

**ALWAYS** show the grpcurl command to the user and ask for confirmation before executing it, unless the user explicitly tells you to skip confirmation (e.g., "don't ask for confirmation").

Format the command clearly with line breaks for readability.

### 5. Handle Responses

After executing the command:
- Display the response clearly
- Format JSON responses for readability
- If there's an error, explain what went wrong and suggest fixes
- If the response is large, summarize key information

## Common Operations

### Query Operations (StreamingAdminSystem)

- `ListStreams` - List all streams
- `GetStream` - Get details for a specific stream (requires `stream_id`)
- `ListKafkaClusters` - List all Kafka clusters
- `ListAssigners` - List all assigners
- `GetTopicsForStream` - Get topics for a stream (requires `stream_id`)
- `GetBackfillsForStream` - Get backfills for a stream (requires `stream_id`)
- `GetStreamConsumerGroups` - Get consumer groups for a stream (requires `stream_id`)
- `GetTasks` - Get task status information

### Stream Operations (StreamOperations)

- `CreateStream` - Create a new stream
- `UpdateStream` - Update stream configuration
- `DeleteStream` - Delete a stream
- `CreateStreamConsumerGroup` - Create a consumer group
- `UpdateStreamConsumerGroup` - Update consumer group
- `DeleteStreamConsumerGroup` - Delete consumer group
- `PauseStreamConsumerGroup` / `UnpauseStreamConsumerGroup` - Pause/unpause consumption
- `CreateBackfill` - Create a backfill
- `UpdateBackfill` - Update backfill configuration
- `FailoverTopic` - Trigger topic failover

## Examples

### Example 1: List all streams

**Parameters**: dc=us1, env=staging, instance=metrics

```bash
grpcurl \
  -H "X-datadog-target-release: streaming-admin-metrics.streaming" \
  -d '{}' \
  streaming-admin-metrics.us1.staging.dog:443 \
  streamingadmingrpc.StreamingAdminSystem/ListStreams
```

### Example 2: Get topics for a specific stream

**Parameters**: dc=us1, env=staging, instance=metrics, stream_id=my-test-stream

```bash
grpcurl \
  -H "X-datadog-target-release: streaming-admin-metrics.streaming" \
  -d '{"stream_id": "my-test-stream"}' \
  streaming-admin-metrics.us1.staging.dog:443 \
  streamingadmingrpc.StreamingAdminSystem/GetTopicsForStream
```

### Example 3: Pause a stream consumer group

**Parameters**: dc=us1, env=staging, instance=metrics, stream_id=my-stream, consumer_group=my-cg

```bash
grpcurl \
  -H "X-datadog-target-release: streaming-admin-metrics.streaming" \
  -d '{"stream_id": "my-stream", "stream_consumer_group": "my-cg"}' \
  streaming-admin-metrics.us1.staging.dog:443 \
  streamingadmingrpc.StreamOperations/PauseStreamConsumerGroup
```

## Additional Resources

- Proto definitions: `logs-backend/libs/grpc/streaming-admin/src/main/resources/streaming/admin/`
- Example HTTP requests: `logs-backend/libs/grpc/streaming-admin/src/main/resources/requests/streaming-admin.http`
- Full service documentation: Check the proto files for complete RPC definitions and message formats

## Tips

1. When the user provides a partial command or operation name, help them by suggesting the correct RPC method name.
2. For complex operations like CreateStream or CreateBackfill, refer to the proto definitions to understand required fields.
3. If a command fails with "method not found", double-check the service package and method name against the proto files.
4. Port 443 should be used for all connections (HTTPS).
5. Always include the header `-H "X-datadog-target-release: streaming-admin-{instance}.streaming"` in every request.
6. If you need to issue a requesto to the streaming-assigner for a stream, first get the stream from the streaming-admin to know what streaming-assigner deployment to target.

