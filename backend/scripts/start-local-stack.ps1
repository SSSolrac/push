param(
  [switch]$StopExisting
)

$ErrorActionPreference = "Stop"
$BackendRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Runtime = Join-Path $BackendRoot ".runtime"
New-Item -ItemType Directory -Force -Path $Runtime | Out-Null

$RequiredPaths = @(
  (Join-Path $BackendRoot "services/points-engine/dist/server.js"),
  (Join-Path $BackendRoot "services/campaign-service/dist/server.js"),
  (Join-Path $BackendRoot "services/gateway/dist/server.js")
)

$Missing = $RequiredPaths | Where-Object { -not (Test-Path $_) }
if ($Missing.Count -gt 0) {
  Write-Output "Local stack is not built yet. Run this first:"
  Write-Output "cd backend"
  Write-Output "npm run setup:local"
  Write-Output ""
  Write-Output "Missing:"
  $Missing | ForEach-Object { Write-Output " - $_" }
  exit 1
}

$Ports = @(4000, 4001, 4002)

if ($StopExisting) {
  foreach ($Port in $Ports) {
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
      $Process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
      if ($Process -and $Process.ProcessName -match "node|npm|powershell") {
        Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
      }
    }
  }
  Start-Sleep -Seconds 1
}

$Services = @(
  @{
    Name = "points-engine"
    WorkingDirectory = Join-Path $BackendRoot "services/points-engine"
    Arguments = @("dist/server.js")
  },
  @{
    Name = "campaign-service"
    WorkingDirectory = Join-Path $BackendRoot "services/campaign-service"
    Arguments = @("dist/server.js")
  },
  @{
    Name = "gateway"
    WorkingDirectory = Join-Path $BackendRoot "services/gateway"
    Arguments = @("dist/server.js")
  }
)

$Node = (Get-Command node.exe -ErrorAction Stop).Source

foreach ($Service in $Services) {
  $OutLog = Join-Path $Runtime "$($Service.Name).out.log"
  $ErrLog = Join-Path $Runtime "$($Service.Name).err.log"
  Set-Content -Path $OutLog -Value ""
  Set-Content -Path $ErrLog -Value ""

  $Process = Start-Process -FilePath $Node `
    -ArgumentList $Service.Arguments `
    -WorkingDirectory $Service.WorkingDirectory `
    -RedirectStandardOutput $OutLog `
    -RedirectStandardError $ErrLog `
    -WindowStyle Hidden `
    -PassThru

  Set-Content -Path (Join-Path $Runtime "$($Service.Name).pid") -Value $Process.Id
  Write-Output "$($Service.Name) pid=$($Process.Id)"
}

function Wait-Health {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Url
  )

  for ($Attempt = 0; $Attempt -lt 30; $Attempt++) {
    try {
      $Response = Invoke-RestMethod -Method GET -Uri $Url -TimeoutSec 2
      if ($Response.ok -eq $true) {
        Write-Output "$Name healthy at $Url"
        return
      }
    } catch {
      Start-Sleep -Milliseconds 500
    }
  }

  throw "$Name did not become healthy at $Url"
}

Wait-Health -Name "gateway" -Url "http://127.0.0.1:4000/health"
Wait-Health -Name "points-engine" -Url "http://127.0.0.1:4001/health"
Wait-Health -Name "campaign-service" -Url "http://127.0.0.1:4002/health"
