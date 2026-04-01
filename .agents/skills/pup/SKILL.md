---
name: pup
description: Use pup, Datadog's internal API CLI, to authenticate and interact with Datadog APIs from the terminal and/or anytime to fetch data from a datadog link. Use when Codex needs to inspect or modify Datadog resources, choose the correct site or org, use OAuth2 or dd-auth-based authentication, run in read-only or agent mode, or work with monitors, logs, metrics, dashboards, SLOs, users, incidents, and events through pup.
---

# Pup

## Overview

Use `pup` to work with Datadog APIs from the terminal.
Prefer safe execution: authenticate without exposing secrets, choose the correct site and org, and use `--read-only` unless the task requires a write.

Binary: `/opt/homebrew/bin/pup`

If `pup` is not on `PATH`, invoke it with the full path.

## Authenticate

Prefer `dd-auth` wrapping when available so credentials are injected non-interactively:

```bash
dd-auth --domain app.datadoghq.com -- pup test
dd-auth --domain app.datadoghq.com -- pup monitors list
dd-auth --domain dd.datad0g.com -- pup logs search --query "service:foo" --from 1h
```

Use these common domains:

| Domain | Environment |
| --- | --- |
| `app.datadoghq.com` | US1 prod |
| `ddstaging.datadoghq.com` | US1 staging org |
| `dd.datad0g.com` | US1 staging |
| `datadoghq.eu` | EU1 |

Fall back to native OAuth2 when `dd-auth` is unavailable:

```bash
pup auth login
DD_SITE=datadoghq.eu pup auth login

pup auth status
pup auth refresh
pup auth logout
```

Tokens are cached in `~/.config/pup/tokens_<site>.json`.
Never print or paste credentials or raw token values into chat or logs.

## Choose Output And Safety Flags

Use `--agent` when another tool or model will parse the output.

```bash
pup --agent monitors list
pup --agent logs search --query "service:foo" --from 30m
```

Use these flags deliberately:

| Flag | Use |
| --- | --- |
| `-o json` | Return machine-friendly output |
| `-o table` | Return human-readable terminal output |
| `-o yaml` | Return structured YAML |
| `--agent` | Return structured agent-oriented output |
| `--read-only` | Block destructive operations while exploring |
| `--org <name>` | Select a named org session |
| `-y` | Auto-approve destructive operations |

Prefer `--read-only` for discovery and inspection work.

## Run Common Commands

Start with `pup test` to verify auth and site selection.

```bash
pup test

pup monitors list
pup monitors get <id>

pup logs search --query "service:my-service status:error" --from 1h

pup metrics query --query "avg:system.cpu.user{*}"

pup dashboards list
pup slos list
pup users list
pup incidents list
pup events list

pup auth token
```

Use `pup auth token` only when another tool needs a bearer token immediately, such as `curl`.
Do not read token cache files directly unless there is a specific reason.

## Links

When giving me back links, always use app.datadoghq.com domain but set the datacenter parameter accordingly

## Handle Multi-Site And Multi-Org Usage

Set `DD_SITE` before login when working outside the default site:

```bash
DD_SITE=datadoghq.eu pup auth login
```

For multi-org setups, log in once per org and then select the org on each command:

```bash
pup auth login --org my-org
pup --org my-org monitors list
```

Confirm the site and org before running any write operation.

## Guardrails

- Prefer `--read-only` unless the user explicitly asks for a mutation.
- Prefer `--agent` when the output will be consumed programmatically.
- Verify the site, org, and target resource before using `-y`.
- Avoid echoing credentials, tokens, or command output that contains secrets.

