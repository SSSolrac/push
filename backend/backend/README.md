# System 3 NestJS Backend

NestJS backend for local API testing on port `4000`.

## Windows PowerShell

```powershell
cd backend\backend
npm install
npm run build
npm run start:dev
```

Run the frontend separately:

```powershell
cd frontend
npm run dev
```

Health checks:

```powershell
Invoke-RestMethod http://localhost:4000/health
Invoke-RestMethod http://localhost:4000/segments
Invoke-RestMethod http://localhost:4000/rewards
Invoke-RestMethod http://localhost:4000/partners/dashboard
Invoke-RestMethod http://localhost:4000/communications/analytics
```

Local/demo mode reads and writes `../.runtime/api-store.json` from `backend/backend`. If Supabase env is missing or invalid, the backend stays usable with local fallback data.

## Supabase

For real persistence, create `backend/backend/.env` or `backend/.env.local` with backend-safe variables:

```powershell
PORT=4000
USE_LOCAL_LOYALTY_API=false
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

Run the SQL files in Supabase SQL Editor when migrations are present. The migrations are idempotent and seed the default tiers and rewards.
