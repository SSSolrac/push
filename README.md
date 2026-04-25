# SYSTEM-3-Revise

Local loyalty platform for System 3.

## Structure

```text
frontend/
  src/
  utils/
  package.json

backend/
  backend/
  services/
    points-engine/
    campaign-service/
    gateway/
  scripts/
```

ONLY `frontend/` and `backend/` are application folders at the repository root. `postman/` is API tooling, not an application folder.

## Frontend

```powershell
cd frontend
npm ci
npm run dev
npm run build
```

The frontend runs on `http://127.0.0.1:3000`. For real Supabase persistence, copy the root `.env.example` values into `frontend/.env.local`.

## Backend

Nest backend:

```powershell
cd backend\backend
npm ci
npm run build
npm run start:dev
```

Microservices:

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

Ports:

```text
gateway: 4000
points-engine: 4001
campaign-service: 4002
```

## Local QA

Use PowerShell from `frontend/`:

```powershell
npm run setup:local
npm run local
npm run qa
```

Open the app at:

```text
http://127.0.0.1:3000/admin/settings
```

Use `127.0.0.1`, not `localhost`, for local QA and Postman. If Chrome shows `chrome-error://chromewebdata`, the local server is not running yet. Run `npm run local` again and verify ports `3000`, `4000`, `4001`, and `4002` are listening.
