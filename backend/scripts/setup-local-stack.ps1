$ErrorActionPreference = "Stop"

$BackendRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$NestBackendRoot = Join-Path $BackendRoot "backend"
$Services = @(
  "services/points-engine",
  "services/campaign-service",
  "services/gateway"
)

function Invoke-Npm {
  param(
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  Write-Output "npm $($Arguments -join ' ') [$WorkingDirectory]"
  Push-Location $WorkingDirectory
  try {
    & npm @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "npm $($Arguments -join ' ') failed in $WorkingDirectory"
    }
  } finally {
    Pop-Location
  }
}

Invoke-Npm -WorkingDirectory $NestBackendRoot -Arguments @("ci")
Invoke-Npm -WorkingDirectory $NestBackendRoot -Arguments @("run", "build")

foreach ($Service in $Services) {
  $ServicePath = Join-Path $BackendRoot $Service
  Invoke-Npm -WorkingDirectory $ServicePath -Arguments @("ci")
  Invoke-Npm -WorkingDirectory $ServicePath -Arguments @("run", "build")
}

Write-Output "Backend local stack setup complete. From backend/ run: npm run local"
