$ErrorActionPreference = "Stop"

$BackendRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$RepoRoot = Resolve-Path (Join-Path $BackendRoot "..")
$DockerComposePath = Join-Path $RepoRoot "docker-compose.yml"
$FrontendPackagePath = Join-Path $RepoRoot "frontend/package.json"

function Assert-PathMissing {
  param(
    [Parameter(Mandatory = $true)][string]$RelativePath,
    [Parameter(Mandatory = $true)][string]$Message
  )

  $FullPath = Join-Path $RepoRoot $RelativePath
  if (Test-Path $FullPath) {
    throw $Message
  }
}

Assert-PathMissing -RelativePath "src" -Message "Root src/ must not exist."
Assert-PathMissing -RelativePath "utils" -Message "Root utils/ must not exist."
Assert-PathMissing -RelativePath "services" -Message "Root services/ must not exist."
Assert-PathMissing -RelativePath "scripts" -Message "Root scripts/ must not exist."
Assert-PathMissing -RelativePath "package.json" -Message "Root package.json must not exist."
Assert-PathMissing -RelativePath "package-lock.json" -Message "Root package-lock.json must not exist."
Assert-PathMissing -RelativePath "loyalty-frontend" -Message "Unexpected loyalty-frontend folder found."
Assert-PathMissing -RelativePath "loyalty-backend" -Message "Unexpected loyalty-backend folder found."
Assert-PathMissing -RelativePath "apps" -Message "Unexpected apps/ folder found."
Assert-PathMissing -RelativePath "packages" -Message "Unexpected packages/ folder found."

$FrontendPackage = Get-Content $FrontendPackagePath | ConvertFrom-Json
$FrontendScripts = @{}
if ($FrontendPackage.scripts) {
  $FrontendPackage.scripts.PSObject.Properties | ForEach-Object {
    $FrontendScripts[$_.Name] = [string]$_.Value
  }
}

$BlockedFrontendScripts = @(
  "setup:backend",
  "dev:backend",
  "build:backend",
  "start:backend",
  "setup:local",
  "local",
  "qa"
)

foreach ($ScriptName in $BlockedFrontendScripts) {
  if ($FrontendScripts.ContainsKey($ScriptName)) {
    throw "frontend/package.json must not define backend orchestration script '$ScriptName'."
  }
}

foreach ($Entry in $FrontendScripts.GetEnumerator()) {
  if ($Entry.Value -match "\.\./backend" -or $Entry.Value -match "backend/scripts") {
    throw "frontend/package.json must not reference backend scripts or backend package paths."
  }
}

$DockerCompose = Get-Content $DockerComposePath -Raw
$RequiredContexts = @(
  "./backend/services/gateway",
  "./backend/services/points-engine",
  "./backend/services/campaign-service"
)

foreach ($Context in $RequiredContexts) {
  if ($DockerCompose -notmatch [regex]::Escape($Context)) {
    throw "docker-compose.yml must reference build context '$Context'."
  }
}

$Rg = Get-Command rg -ErrorAction SilentlyContinue
if ($Rg) {
  $SearchRoots = @("README.md", "frontend", "backend", ".github", "docker-compose.yml")
  $Patterns = @(
    "loyalty-frontend",
    "loyalty-backend",
    "\.\./services",
    "\.\./scripts"
  )

  Push-Location $RepoRoot
  try {
    foreach ($Pattern in $Patterns) {
      & $Rg.Source -n --glob "!**/node_modules/**" --glob "!**/dist/**" --glob "!**/.next/**" --glob "!.git/**" --glob "!backend/scripts/validate-split.ps1" $Pattern @SearchRoots | Out-String | ForEach-Object {
        if ($_.Trim()) {
          throw "Stale reference detected for pattern '$Pattern': $($_.Trim())"
        }
      }
    }
  } finally {
    Pop-Location
  }
}

Write-Output "Split validation passed."
