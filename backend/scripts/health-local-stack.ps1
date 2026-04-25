$ErrorActionPreference = "Stop"

$Urls = @(
  @{ Name = "gateway"; Url = "http://127.0.0.1:4000/health" },
  @{ Name = "points-engine"; Url = "http://127.0.0.1:4001/health" },
  @{ Name = "campaign-service"; Url = "http://127.0.0.1:4002/health" }
)

foreach ($Entry in $Urls) {
  $Timer = [Diagnostics.Stopwatch]::StartNew()
  try {
    $Response = Invoke-RestMethod -Method GET -Uri $Entry.Url -TimeoutSec 10
    $Timer.Stop()
    if ($Response.ok -ne $true) {
      throw "$($Entry.Name) returned ok=$($Response.ok)"
    }
    Write-Output "$($Entry.Name) OK $([math]::Round($Timer.Elapsed.TotalMilliseconds))ms"
  } catch {
    $Timer.Stop()
    throw "$($Entry.Name) health check failed after $([math]::Round($Timer.Elapsed.TotalMilliseconds))ms: $($_.Exception.Message)"
  }
}
