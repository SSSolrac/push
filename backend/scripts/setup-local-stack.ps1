$ErrorActionPreference = "Stop"

$BackendRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ProjectRoot = Resolve-Path (Join-Path $BackendRoot "..")
$FrontendRoot = Join-Path $ProjectRoot "frontend"
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

Invoke-Npm -WorkingDirectory $FrontendRoot -Arguments @("install")
Invoke-Npm -WorkingDirectory $NestBackendRoot -Arguments @("install")
Invoke-Npm -WorkingDirectory $NestBackendRoot -Arguments @("run", "build")

foreach ($Service in $Services) {
  $ServicePath = Join-Path $BackendRoot $Service
  Invoke-Npm -WorkingDirectory $ServicePath -Arguments @("install")
  Invoke-Npm -WorkingDirectory $ServicePath -Arguments @("run", "build")
}

Write-Output "Local stack setup complete. From frontend/ run: npm run local"
