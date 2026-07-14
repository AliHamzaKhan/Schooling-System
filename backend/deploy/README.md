# Backend deployment — AHKStudios VPS

This directory holds the production compose file the CI pipeline ships to
`/opt/apps/school/backend/` on the shared VPS. The pipeline itself lives at
the repo root (`.gitlab-ci.yml`).

## Architecture recap

- Shared VPS `161.97.98.16`, single Postgres 17 + Redis 7 on the `app-network`.
- No public ports on the app container — Nginx Proxy Manager (NPM) routes
  `school.ahkstudios.com/api/*` → `school-backend:8000` over `app-network`.
- Image is built + pushed by GitLab CI to
  `registry.gitlab.com/alihamza.khan05/schooling_system/backend`.
- On deploy, the container runs `alembic upgrade head`, then `python -m app.seed`
  (idempotent), then `uvicorn` with 4 workers.

## One-time server setup

On the VPS as `ahkstudios`:

```bash
# 1) Database (pick a strong password, URL-encode '#' as %23 in DATABASE_URL below)
docker exec -it postgres psql -U ahkstudios -c "CREATE DATABASE school_db;"

# 2) App + uploads directories
mkdir -p /opt/apps/school/backend
mkdir -p /opt/storage/projects/school
sudo chown -R 999:999 /opt/storage/projects/school

# 3) Deploy SSH key — add the *public* half to ~/.ssh/authorized_keys
#    Generate the pair locally: ssh-keygen -t ed25519 -N "" -f ./school_deploy
#    Then: base64 -w0 school_deploy   (that value goes into SSH_PRIVATE_KEY_B64)
```

## DNS + NPM

1. `school.ahkstudios.com` A record → `161.97.98.16`.
2. In NPM (`http://161.97.98.16:81`), add a **Proxy Host**:
   - Domain: `school.ahkstudios.com`
   - Custom location `/api` → `http` `school-backend` port `8000`
     (leave root `/` free for the future frontend container).
   - **Advanced** for that location — preserve the `/api` prefix and forward
     real IPs:
     ```
     proxy_set_header Host $host;
     proxy_set_header X-Real-IP $remote_addr;
     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
     proxy_set_header X-Forwarded-Proto $scheme;
     ```
   - SSL: request a Let's Encrypt cert, Force SSL, HTTP/2.

The FastAPI app already mounts routes under `/api/v1`, so requests land as
`https://school.ahkstudios.com/api/v1/...`.

## Required GitLab CI/CD variables

Settings → CI/CD → Variables. **Mask + Protect** every secret.

| Variable | Type | Example / notes |
|---|---|---|
| `SSH_HOST` | Variable | `161.97.98.16` |
| `SSH_USER` | Variable | `ahkstudios` |
| `SSH_PRIVATE_KEY_B64` | File/Variable (masked) | `base64 -w0` of a passphrase-less deploy key |
| `DATABASE_URL` | Variable (masked) | `postgresql+asyncpg://ahkstudios:<url-encoded-pw>@postgres:5432/school_db` |
| `REDIS_URL` | Variable | `redis://redis:6379/1` (use a distinct DB index per project) |
| `JWT_SECRET_KEY` | Variable (masked) | `openssl rand -hex 32` |
| `FIRST_SUPERADMIN_EMAIL` | Variable | `admin@ahkstudios.com` |
| `FIRST_SUPERADMIN_PASSWORD` | Variable (masked) | strong password |
| `BACKEND_CORS_ORIGINS` | Variable | `["https://school.ahkstudios.com"]` |

Optional provider credentials (leave unset for stub/log mode): `TWILIO_ACCOUNT_SID`,
`TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`, `TWILIO_SMS_FROM`, `FCM_SERVER_KEY`,
`EMAIL_FROM`, `ANTHROPIC_API_KEY`, `STORAGE_BACKEND`.

## Trigger a deploy

Push to `main` (or click **Run pipeline** in GitLab). Pipeline stages:
`lint → test → build → deploy`. The deploy job SSHes in, writes `.env`,
`docker compose pull && up -d`, then polls `/health` until it returns 200.

## Rollback

```bash
# On the VPS
cd /opt/apps/school/backend
# Pin to a previous SHA (from the GitLab registry tags)
sed -i "s/^IMAGE_TAG=.*/IMAGE_TAG=<old-sha>/" .env
docker compose pull && docker compose up -d
```

## Notes

- The container writes uploads to `/app/uploads`, backed by
  `/opt/storage/projects/school` on the host.
- The seed script (`python -m app.seed`) is idempotent — safe to run every
  deploy. If you'd rather run it manually, drop that step from
  `deploy/docker-compose.prod.yml`'s `command:`.
- `--proxy-headers --forwarded-allow-ips='*'` on uvicorn is required so
  redirects and client IPs work correctly behind NPM.
