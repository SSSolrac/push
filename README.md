# SYSTEM-3-Revise

Local loyalty platform for System 3.

## Structure

```text
frontend/
  src/
  utils/
  package.json

backend/
  package.json
  backend/
  services/
    points-engine/
    campaign-service/
    gateway/
  scripts/
```

ONLY `frontend/` and `backend/` are application folders at the repository root. `postman/` is API tooling, not an application folder.

`frontend/` is only for the Next.js member/admin portal. `backend/` is only for the Nest backend app, backend services, and backend orchestration scripts.

Normal repo metadata may also exist at the root, such as `.git/`, `.github/`, `.gitignore`, and `.env.example`. There is no root `package.json`.

## Frontend

Run the portal independently from `frontend/`:

```powershell
cd frontend
npm ci
npm run dev
npm run build
npm start
```

The frontend runs on `http://127.0.0.1:3000`. For real Supabase persistence, copy the root `.env.example` values into `frontend/.env.local`.

## Backend

Run backend orchestration independently from `backend/`:

```powershell
cd backend
npm ci
npm run validate:split
npm run setup:local
npm run local
npm run health
npm run qa
```

The backend local stack starts the gateway and services:

```text
gateway: 4000
points-engine: 4001
campaign-service: 4002
```

Run the Nest backend app directly from `backend/backend/`:

```powershell
cd backend\backend
npm ci
npm run build
npm run start:dev
```

Run services directly when needed:

```powershell
cd backend\services\points-engine
npm ci
npm run build
npm start

cd ..\campaign-service
npm ci
npm run build
npm start

cd ..\gateway
npm ci
npm run build
npm start
```

## Docker

Use Docker Compose from the repository root:

```powershell
docker compose config
docker compose up --build gateway points-engine campaign-service
```

The compose file builds from `backend/services/gateway`, `backend/services/points-engine`, and `backend/services/campaign-service`.

## CI

`frontend.yml` builds the Next.js app from `frontend/` and only runs tests when a frontend test script exists.

`backend.yml` validates the backend orchestration package, runs the split guardrail script, and then builds/tests the Nest backend plus each service from their own directories.

Use `127.0.0.1`, not `localhost`, for local QA and Postman. If a health check fails, verify ports `4000`, `4001`, and `4002` are listening.
