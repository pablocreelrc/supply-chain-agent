<#
  verify-trace.ps1 - destination-verified first-trace gate (Windows).

  Config looking correct is NOT proof telemetry works. This queries Langfuse
  DIRECTLY and exits 0 only if a trace tagged with THIS operator's
  service.name + user.id actually landed in the last N minutes.

  Run AFTER your first real agent prompt (Windows PowerShell 5.1 or pwsh):
    op run --env-file=.env -- powershell -File ./scripts/verify-trace.ps1

  Generic by design: reads OTEL_SERVICE_NAME + USER_ID from the env, so the
  same script works unchanged for every ai-agents-* agent. Copy as-is.
  ASCII-only on purpose: PS 5.1 reads UTF-8 files as CP1252 and non-ASCII
  punctuation breaks the parser.

  Exit: 0 = a trace for you landed. 1 = nothing found / misconfig.
#>
param([int]$WindowMin = 15)
# NOT 'Stop': npx is a native exe; PS 5.1 wraps its stderr as a terminating
# NativeCommandError under Stop, which would falsely fail this gate.
$ErrorActionPreference = "Continue"

if (-not $env:LANGFUSE_HOST) { $env:LANGFUSE_HOST = $env:LANGFUSE_BASE_URL }

$missing = $false
foreach ($v in @("LANGFUSE_PUBLIC_KEY","LANGFUSE_SECRET_KEY","LANGFUSE_HOST","OTEL_SERVICE_NAME","USER_ID")) {
  if (-not [Environment]::GetEnvironmentVariable($v)) {
    Write-Host ("  [FAIL] {0} not set - launch via 'op run --env-file=.env -- powershell -File ./scripts/verify-trace.ps1'" -f $v)
    $missing = $true
  }
}
if ($missing) { exit 1 }

$since = (Get-Date).ToUniversalTime().AddMinutes(-$WindowMin).ToString("yyyy-MM-ddTHH:mm:ssZ")
$svc   = $env:OTEL_SERVICE_NAME
$uid   = $env:USER_ID

# Server-side datetime filter only (nested resourceAttributes are NOT
# filterable server-side in langfuse-cli; limit max is 100). Operator/agent
# match is done client-side against metadata.resourceAttributes.
$filter = '[{"type":"datetime","column":"timestamp","operator":">=","value":"' + $since + '"}]'
# PS 5.1 strips embedded double quotes when passing an arg to a native exe;
# escape them as \" so langfuse-cli receives valid JSON.
$filterArg = $filter -replace '"','\"'

Write-Host ("Querying Langfuse for service.name={0} user.id={1} since {2} ..." -f $svc,$uid,$since)
# Do not redirect npx stderr in PS 5.1 (it gets ErrorRecord-wrapped). stdout
# carries the JSON; any stderr just prints as console noise and is harmless.
$raw = (& npx -y langfuse-cli api traces list --limit 100 --fields core,io --filter $filterArg | Out-String)

$count = 0
try {
  $data = ($raw | ConvertFrom-Json).data
  foreach ($t in $data) {
    $ra = $t.metadata.resourceAttributes
    if ($ra -and $ra.'service.name' -eq $svc -and $ra.'user.id' -eq $uid) { $count++ }
  }
} catch { $count = -1 }

if ($count -ge 1) {
  Write-Host ("  [OK] {0} trace(s) for you landed in Langfuse. Telemetry is live." -f $count)
  exit 0
}

Write-Host ("  [FAIL] ZERO traces for service.name={0} user.id={1} in the last {2} min." -f $svc,$uid,$WindowMin)
Write-Host ("         Widen the window with: powershell -File ./scripts/verify-trace.ps1 -WindowMin 60")
Write-Host ("         This is the silent failure. Checklist:")
Write-Host ("         1. Did you launch via 'op run --env-file=.env -- claude' (NOT plain 'claude')?")
Write-Host ("         2. Did you actually send one real prompt to the agent first?")
Write-Host ("         3. 'op whoami' still returns SERVICE_ACCOUNT?")
Write-Host ("         4. Re-run 'install this agent' to re-validate the OTEL endpoint.")
if ($count -eq -1) { Write-Host ("         Note: langfuse-cli returned no parseable data - check LANGFUSE_* creds resolved.") }
exit 1
