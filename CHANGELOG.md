# Changelog: what was changed from the original app, and why

This documents every change made to the application code you uploaded
(`Dream-Vacation-Capstone-main.zip`), plus everything added on top of it for
the DevOps side. Nothing about the app's actual behavior changed - same
endpoints, same UI flow, same external API - only fixes and additions.

## Backend (`backend/`)

| File | Change | Why |
|---|---|---|
| `server.js` | Added `/api/health` endpoint | Needed for Docker healthchecks, CI smoke tests, and load balancer probes - didn't exist before |
| `server.js` | Split DB pool + schema creation into `db.js`, called on startup | The original app assumed a `destinations` table already existed with no migration/setup anywhere. A fresh DB (new Docker volume, CI's throwaway Postgres) would 500 on every request. Now it's created automatically if missing |
| `server.js` | Wrapped `app.listen()` in `if (require.main === module)`, added `module.exports = app` | Makes the app importable by tests (via `supertest`) without opening a real port/DB connection |
| `server.js` | `POST /api/destinations` now returns 400 for a missing/blank `country`, 404 if the REST Countries API finds nothing, and no longer crashes if `countryInfo` is undefined | The original would throw an unhandled exception (500 or a crash) on a typo'd country name, since `countryInfo.capital` was accessed without checking `countryInfo` existed |
| `db.js` | New file | Houses the connection pool and `initSchema()` |
| `server.test.js` | New file | Minimal smoke tests (`/api/health`, input validation) - this is what was missing and caused your `Missing script: "test"` / `No tests found` CI errors |
| `package.json` | Added `"test": "jest --passWithNoTests"` and `"lint": "eslint . --ext .js"` scripts, added `jest`, `supertest`, `eslint` to devDependencies | These scripts didn't exist at all before, which is the direct cause of the `npm error Missing script` failures you hit |
| `.eslintrc.json` | New file | Config for the new lint script |
| `.env.example` | New file | Documents `PORT`, `DATABASE_URL`, `COUNTRIES_API_BASE_URL` |
| `Dockerfile`, `.dockerignore` | New | Multi-stage build, non-root user, healthcheck hitting `/api/health` |

## Frontend (`frontend/`)

| File | Change | Why |
|---|---|---|
| `package.json` | Bumped `react-scripts` from `3.0.1` → `5.0.1` | This was a real, pre-existing bug: `react-scripts@3.0.1` (2019) was paired with `react@18.2.0` and `@testing-library/react@13` (built for React 18). That mismatch is exactly the kind of thing that produces confusing, hard-to-diagnose build/test failures. `react-scripts@5.0.1` is the version actually meant to run React 18, and its ESLint peer range (`^7 \|\| ^8`) is compatible with the `eslint@8.57.0` now in devDependencies - avoiding the "different version of eslint was detected" preflight error entirely, at the root, rather than by removing lint/deleting eslint |
| `package.json` | `"test": "react-scripts test --watchAll=false --passWithNoTests"` | Prevents CI from hanging in watch mode or failing on "No tests found" |
| `package.json` | Added `"lint": "eslint src --ext .js,.jsx"` | Didn't exist before - same root cause as the backend's missing lint script |
| `src/App.js` | Same state/handlers (`fetchDestinations`, `handleSubmit`, `handleDelete`, same endpoints) plus: loading/error/empty states, a submitting-state on the button, and inline form-error feedback (e.g. "No country found matching…") | You flagged the app "isn't quite presentable" - functionally it was a bare, unstyled `<ul>` with no feedback for errors or empty states |
| `src/App.css`, `src/index.css` | New files | Actual styling - card layout, form, typography. There was no CSS in the app at all before |
| `src/App.test.js` | New file | Smoke test (mocks `axios`, renders the empty state) |
| `.env.example`, `.dockerignore`, `Dockerfile`, `nginx.container.conf` | New | Multi-stage build serving the React bundle via Nginx, which also proxies `/api/*` to the backend container |

## Removed

- `backend/package-lock.json`, `frontend/package-lock.json` - deleted because dependencies changed (react-scripts, added devDependencies). **You need to regenerate these** by running `npm install` in each directory and committing the result - see `COMMIT_PLAN.md` Day 1. CI's `actions/setup-node` cache step expects these lockfiles to exist.

## Added (DevOps layer - none of this existed before)

- `docker-compose.yml`, root `.env.example` - one-command local stack
- `.github/workflows/ci.yml` - lint/test/build on PRs into `main`/`staging`/`develop` (matching the branch strategy already in `Contributing.md`), plus push to `develop`
- `.github/workflows/cd.yml` - build & push images to GHCR on merge to `main`, optional SSH auto-deploy
- `.github/pull_request_template.md`
- `terraform/` - VPC, subnets, security groups, EC2 + Elastic IP, Route 53, remote state (S3 + DynamoDB)
- `scripts/` - `setup-env.sh`, `backup-db.sh`, `rotate-logs.sh`, `install-cron.sh`, `deploy.sh`
- `nginx/dream-vacations.conf` - host-level reverse proxy, Certbot-ready
- `docs/` - git workflow, domain/DNS, full deployment guide, CloudWatch stretch goal
- `LICENSE` (MIT), extended `.gitignore` (Terraform state, build output, logs, coverage)

## What did *not* change

- The core data flow: add a country → backend calls REST Countries API →
  stores capital/population/region → lists/deletes from Postgres. Identical
  to your original `server.js`/`App.js` logic.
- `Contributing.md`'s branching model (`main`/`staging`/`develop`) - CI/CD
  and branch protection docs were built to match it, not replace it.
