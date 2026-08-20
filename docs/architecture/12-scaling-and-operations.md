# Scaling & Operations

How the backend scales horizontally and the operational surfaces added for it.
The service is a **modular monolith** run as N stateless API instances (plus an
optional worker) behind a load balancer — not microservices. See
`backend/app/core/` for the pieces referenced below.

## Horizontal scaling model

The API is **stateless**: auth is JWT (access token + rotating refresh session
in Postgres), rate-limit counters live in Redis, and uploads go to pluggable
object storage — nothing is pinned to one instance. So you scale by running more
instances behind the load balancer:

```bash
# prod compose (deploy/docker-compose.prod.yml)
docker compose up -d --scale backend=3
```

Each instance also runs `uvicorn --workers 4`, so concurrency ≈ `instances × 4`.

## Database connection pooling

Pool size is **per worker process**, so the ceiling of Postgres connections is:

```
(DB_POOL_SIZE + DB_MAX_OVERFLOW) × workers × instances
```

With the defaults (`10 + 20`) × 4 workers × 3 instances = **360** connections —
already above a stock Postgres `max_connections` of 100. Two ways to stay safe:

1. **Lower the per-process pool** (`DB_POOL_SIZE`/`DB_MAX_OVERFLOW`) so the
   product fits under `max_connections`, or
2. **Front Postgres with PgBouncer** in `transaction` pooling mode (recommended
   past a few instances). Point `DATABASE_URL` at PgBouncer instead of Postgres;
   PgBouncer multiplexes many short transactions onto a small pool of real
   connections, so the API can keep generous per-process pools without exhausting
   the database. Note: with `transaction` pooling, server-side prepared
   statements must be disabled — asyncpg does this when reached through PgBouncer;
   keep `pool_pre_ping` on (already set in `database.py`).

## Redis — three uses

`REDIS_URL` powers, in order of importance:

1. **Rate-limit counters** (`app/core/ratelimit.py`) — shared across instances so
   a limit means the same thing everywhere. Production **refuses to boot without
   it** (`config.py`), otherwise per-process counters would multiply every limit
   by the worker/instance count.
2. **Tenant-status cache** (`app/core/cache.py`) — the per-request school +
   subscription check (`enforce_school_context`) is cached for
   `TENANT_STATUS_CACHE_TTL` seconds (default 30) and invalidated on the
   status/subscription mutation paths. Transparent: with no Redis it's a no-op
   and every request hits Postgres as before.
3. **Background-task broker** (`app/core/queue.py` + `app/worker.py`) — see below.

## Background worker

Slow notification fan-out (WhatsApp/SMS/push/email to potentially hundreds of
recipients) is lifted off the request path onto an `arq` worker.

- Enable with `TASK_QUEUE_ENABLED=true` (requires `REDIS_URL`) **and** run at
  least one worker: `arq app.worker.WorkerSettings` (the `worker` service in
  `deploy/docker-compose.prod.yml`). Scale workers independently: `--scale
  worker=2`.
- With the flag off (default) delivery runs inline, unchanged — so enabling
  offload is a deliberate step that can't strand jobs with no consumer.

## Observability

- **Correlation IDs** — every response carries `X-Request-ID` (an inbound one is
  honoured), and every log line for that request includes it, so a request can be
  traced across instances. Format: `… [<request_id>]: <message>`.
- **Access log + latency** — one line per request (method, path, status, ms).
- **Health probes**:
  - `GET /health` — liveness (process up). Used by the container healthcheck.
  - `GET /health/ready` — readiness: checks Postgres and Redis, returns `503`
    when a dependency is down so the load balancer pulls the instance.
- **Metrics** — `GET /metrics` (Prometheus): `http_requests_total` and
  `http_request_duration_seconds` labelled by route template (not raw path, to
  bound cardinality), plus process CPU/memory/FDs. Firewall it to the monitoring
  network.

## Rate limiting

Centralized in `app/core/ratelimit.py`, Redis-backed, keyed **per-user** (JWT
subject) when authenticated else per-IP:

- Global default: `300/min` per key (every route).
- `AUTH_LIMIT` `10/min` on login; `SENSITIVE_LIMIT` `5/min` on the
  forgot/verify-otp/reset/change-password endpoints.
- Breaches return `429` in the standard error envelope (`error.code =
  rate_limited`) with `Retry-After` + `X-RateLimit-*` headers.

## Query-optimization notes

- Tenant/foreign-key columns are indexed (`TenantMixin.school_id`,
  `refresh_sessions.user_id`, `password_resets.user_id`, association tables).
- Known N+1s removed: attendance-alert student lookup (batch load), enrollment
  report (grouped aggregates instead of 2 COUNTs per class).
- When adding list/report endpoints, prefer a single grouped/joined query or
  `selectinload` over per-row lookups, and add a composite index for any new
  `WHERE school_id = ? AND <col> = ?` hot path.

## Environment variables added

| Var | Default | Purpose |
|---|---|---|
| `REDIS_URL` | — (required in prod) | rate limits, cache, task broker |
| `TASK_QUEUE_ENABLED` | `false` | offload notifications to the worker |
| `TENANT_STATUS_CACHE_TTL` | `30` | seconds to cache tenant serviceability (0 = off) |
| `PASSWORD_RESET_OTP_TTL_MINUTES` | `10` | reset OTP validity |
| `PASSWORD_RESET_MAX_ATTEMPTS` | `5` | wrong-OTP guesses before it's burned |
| `PASSWORD_RESET_TOKEN_TTL_MINUTES` | `15` | reset-token validity after OTP verify |
