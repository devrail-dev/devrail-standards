# Monitoring & Observability

Standards for monitoring, logging, metrics, and alerting in DevRail-managed services. These complement the [Output & Logging](../DEVELOPMENT.md#output--logging) section in DEVELOPMENT.md (which covers build-time logging) and the [Container Standards](container-standards.md) health check requirements.

## Health Checks

Every service exposes health endpoints for orchestrators and load balancers:

| Endpoint | Purpose | What It Checks |
|---|---|---|
| `/healthz` | Liveness | Process is running, not deadlocked. Does **not** check external dependencies. |
| `/readyz` | Readiness | Process can serve traffic. Checks database connections, cache availability, required downstream services. |

### Rules

1. **Both endpoints return HTTP 200 for healthy, HTTP 503 for unhealthy.** Response body includes a JSON status and optional detail.
2. **`/healthz` is cheap.** No database queries, no network calls. If the process can respond, it is alive.
3. **`/readyz` checks critical dependencies only.** Do not check every downstream service -- only those without which the service cannot function.
4. **Health checks are unauthenticated.** Orchestrators and load balancers must be able to probe without credentials.
5. **Report dependency status individually** in readiness checks so operators can identify which dependency is down:

   ```json
   {
     "status": "unhealthy",
     "checks": {
       "database": "ok",
       "cache": "timeout",
       "queue": "ok"
     }
   }
   ```

## Structured Application Logging

Build-time logging (Makefile targets, CI jobs, scripts) is covered in [DEVELOPMENT.md Output & Logging](../DEVELOPMENT.md#output--logging). This section covers **runtime application logging** for deployed services.

### Format

Application logs are JSON, one object per line:

```json
{"level":"info","msg":"Request handled","method":"GET","path":"/users","status":200,"duration_ms":42,"request_id":"abc-123","ts":"2026-02-25T10:00:00Z"}
```

### Required Fields

| Field | Purpose |
|---|---|
| `level` | Log level: `debug`, `info`, `warn`, `error` |
| `msg` | Human-readable message |
| `ts` | ISO 8601 timestamp with timezone |
| `request_id` | Correlation ID for tracing a request across services |

### Correlation IDs

1. **Generate a unique `request_id`** at the edge (API gateway, load balancer, or first service).
2. **Propagate the ID** through all downstream service calls via a header (`X-Request-ID`).
3. **Include the ID in every log entry** for the request lifecycle.
4. **Return the ID in the API response** so clients can reference it in support requests.

### Log Levels

| Level | When to Use |
|---|---|
| `debug` | Detailed diagnostic information. Disabled in production by default. |
| `info` | Normal operational events. Request handled, job completed, service started. |
| `warn` | Unexpected but recoverable situations. Retry succeeded, deprecated feature used, approaching limit. |
| `error` | Failures that require attention. Unhandled exception, dependency unreachable, data corruption detected. |

### Rules

1. **Do not use `print` or `console.log` in production code.** Use the language's structured logging library (Python `structlog`/`logging`, Go `slog`, Node `pino`/`winston`).
2. **Log at the appropriate level.** An expected "not found" result is not an error.
3. **Include context, not just messages.** "Failed to connect" is useless. "Failed to connect to database at db.example.com:5432 after 3 retries" is actionable.

## Metrics

### Exposition

Expose metrics in Prometheus format at `/metrics` (or use a platform-specific agent):

```
http_requests_total{method="GET",path="/users",status="200"} 1234
http_request_duration_seconds{method="GET",path="/users",quantile="0.99"} 0.250
```

### RED Method

For every service, instrument the RED signals:

| Signal | Metric | What It Tells You |
|---|---|---|
| **Rate** | `http_requests_total` | How many requests per second |
| **Errors** | `http_requests_total{status=~"5.."}` | What fraction of requests are failing |
| **Duration** | `http_request_duration_seconds` | How long requests take (histogram) |

### Naming Conventions

Follow Prometheus naming conventions:

- Use `snake_case`
- Include the unit as a suffix: `_seconds`, `_bytes`, `_total`
- Counters end with `_total`
- Use labels for dimensions, not separate metric names

### Rules

1. **Instrument the RED signals for every service.** This is the minimum.
2. **Add business metrics where relevant.** Orders placed, messages processed, cache hit ratio.
3. **Do not create high-cardinality labels.** User IDs, request IDs, and IP addresses as labels will overwhelm your metrics backend.
4. **Set appropriate histogram buckets.** Default buckets may not match your service's latency profile.

## Alerting

### Principles

1. **Alert on symptoms, not causes.** "Error rate > 5%" is a symptom. "Database CPU > 80%" is a cause. Alert on the former; investigate the latter during triage.
2. **Every alert must be actionable.** If an alert fires and the correct response is "ignore it", the alert should not exist.
3. **Every alert links to a runbook.** The alert definition includes a URL pointing to the response procedure.
4. **Tune alerts to minimize noise.** False positives erode trust. Use appropriate thresholds, windows, and "for" durations to avoid flapping.

### Severity Mapping

| Alert Severity | Response | Example |
|---|---|---|
| **Critical** | Page on-call immediately | Service down, data loss risk |
| **Warning** | Investigate during business hours | Error rate elevated, disk filling |
| **Info** | Review in next planning cycle | Deprecated API usage increasing |

## Dashboards

### Requirements

1. **One dashboard per service** at minimum, showing the RED signals.
2. **Golden signals visible at a glance:** latency, traffic, errors, saturation.
3. **Time range selectable.** Default to last 1 hour with options for 6h, 24h, 7d.
4. **Link from alert to dashboard.** When an alert fires, the operator can navigate directly to the relevant dashboard.

### Content

| Panel | Metric |
|---|---|
| Request rate | `http_requests_total` rate |
| Error rate | 5xx responses as a percentage |
| Latency (p50, p95, p99) | `http_request_duration_seconds` quantiles |
| Resource utilization | CPU, memory, disk, connections |
| Business metrics | Application-specific KPIs |

## What Not to Log

Certain data must never appear in logs, regardless of log level:

| Category | Examples |
|---|---|
| **Secrets** | API keys, passwords, tokens, private keys |
| **PII** | Email addresses, phone numbers, government IDs, full names (unless required and documented) |
| **Financial data** | Credit card numbers, bank account numbers |
| **Health data** | Medical records, health status |
| **Full request/response bodies** | May contain any of the above. Log selectively. |
| **Session tokens** | Can be used to impersonate users |

### Mitigation

- **Redact at the source.** Use logging middleware that strips sensitive fields before writing.
- **Use allowlists, not blocklists.** Explicitly list which fields to log rather than trying to exclude all sensitive ones.
- **Audit log output.** Periodically review production logs for accidental PII or secret exposure.

## Notes

- Build-time logging (what `make check` outputs, how CI jobs report results) is defined in [DEVELOPMENT.md Output & Logging](../DEVELOPMENT.md#output--logging). This document covers runtime application observability.
- For health check endpoints in containers, see [Container Standards](container-standards.md#health-checks).
- Observability tooling choices (Prometheus, Grafana, Datadog, etc.) are project-specific. These standards define what to measure, not which vendor to use.
