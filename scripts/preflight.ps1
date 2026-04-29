# Supply Chain Agent - preflight check (Windows / PowerShell)
#
# Run from the repo root:
#   .\scripts\preflight.ps1
#
# Verifies that the agent can launch successfully and reports which MCPs
# are configured vs. which will fail gracefully when invoked. Safe to run
# anytime - read-only checks, no state changes.
#
# Exit code: 0 if all critical checks pass, 1 if any critical check fails.
# Critical = op auth, vault access, Langfuse refs resolve, OTEL endpoint
# accepts the auth header. Optional MCPs missing creds is not critical.

$ErrorActionPreference = "Stop"

# Locate repo root (parent of scripts/)
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$EnvFile = Join-Path $RepoRoot ".env"
$McpFile = Join-Path $RepoRoot ".mcp.json"

$script:CriticalFail = $false

function Write-Pass($msg) { Write-Host "  [OK]   " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Fail($msg) { Write-Host "  [FAIL] " -ForegroundColor Red -NoNewline; Write-Host $msg; $script:CriticalFail = $true }
function Write-Warn($msg) { Write-Host "  [WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Info($msg) { Write-Host "  [INFO] " -ForegroundColor Cyan -NoNewline; Write-Host $msg }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " PRE-FLIGHT CHECK - Supply Chain Agent" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# [1/5] op CLI installed and authenticated
Write-Host "[1/5] 1Password CLI authentication"
$opCmd = Get-Command op -ErrorAction SilentlyContinue
if (-not $opCmd) {
    Write-Fail "op CLI not found on PATH"
    Write-Info "Install: winget install AgileBits.1Password.CLI, then restart this terminal"
} elseif (-not $env:OP_SERVICE_ACCOUNT_TOKEN) {
    Write-Fail "OP_SERVICE_ACCOUNT_TOKEN not set in this shell"
    Write-Info "Run: setx OP_SERVICE_ACCOUNT_TOKEN ops_<your-token>, then open a fresh PowerShell window"
} else {
    $whoami = & op whoami 2>&1 | Out-String
    if ($whoami -match "SERVICE_ACCOUNT") {
        Write-Pass "op CLI authenticated as SERVICE_ACCOUNT"
    } else {
        Write-Fail "op whoami did not return SERVICE_ACCOUNT (token invalid or revoked)"
    }
}

# [2/5] AI Agents vault accessible
Write-Host ""
Write-Host "[2/5] AI Agents vault accessible"
if (-not $script:CriticalFail) {
    try {
        $vaults = & op vault list --format=json 2>&1 | ConvertFrom-Json
        $aiVault = $vaults | Where-Object { $_.name -eq "AI Agents" }
        if ($aiVault) {
            Write-Pass ("AI Agents vault visible (id: " + $aiVault.id.Substring(0,8) + "...)")
        } else {
            Write-Fail "AI Agents vault NOT visible to this service account"
            Write-Info "Pablo: grant the service account Read access to AI Agents vault at ajolotelabs.1password.com"
        }
    } catch {
        Write-Fail ("Could not list vaults: " + $_.Exception.Message)
    }
} else {
    Write-Warn "Skipped - op auth failed above"
}

# [3/5] Langfuse 1Password item - all 4 fields resolve correctly
Write-Host ""
Write-Host "[3/5] Langfuse 1Password item resolution"
if (-not $script:CriticalFail) {
    $fields = [ordered]@{
        "auth_header" = "^Authorization=Basic [A-Za-z0-9+/=]+$"
        "public_key"  = "^pk-lf-"
        "secret_key"  = "^sk-lf-"
        "base_url"    = "^https://"
    }
    foreach ($field in $fields.Keys) {
        # Pipe $null to op read to give it closed stdin (PowerShell-native; no cmd needed)
        $val = ($null | & op read "op://AI Agents/Langfuse/$field" 2>&1 | Out-String).Trim()
        if ($val -match $fields[$field]) {
            Write-Pass "$field - resolves with correct shape"
        } else {
            Write-Fail "$field - resolution failed or wrong shape"
        }
    }
} else {
    Write-Warn "Skipped - earlier checks failed"
}

# [4/5] .env file shape
Write-Host ""
Write-Host "[4/5] Supply Chain Agent .env file shape"
if (-not (Test-Path $EnvFile)) {
    Write-Fail (".env file does not exist at " + $EnvFile)
    Write-Info "Run: cp .env.example .env, then fill in USER_ID"
} else {
    $envContent = Get-Content $EnvFile -Raw
    if ($envContent -match "(?m)^USER_ID=[a-zA-Z0-9_-]+$" -and $envContent -notmatch "(?m)^USER_ID=<your-github-handle>") {
        Write-Pass "USER_ID set to a real handle (not placeholder)"
    } else {
        Write-Fail "USER_ID not set or still a placeholder"
    }
    if ($envContent -match "(?m)^USER_ID=pablocreelrc$") {
        Write-Fail "USER_ID is set to 'pablocreelrc' — that handle is reserved for Pablo's own machine. Set it to YOUR GitHub handle."
    }
    if ($envContent -match "(?m)^TENANT=[a-zA-Z0-9_-]+$" -and $envContent -notmatch "(?m)^TENANT=<your-company-slug>") {
        Write-Pass "TENANT set to a real company/engagement slug (not placeholder)"
    } else {
        Write-Fail "TENANT not set or still a placeholder — required for per-customer rollup in Langfuse. Pablo provides the slug; common values: sacrificio, desclub, ajolote, internal."
    }
    if ($envContent -match "(?m)^OTEL_EXPORTER_OTLP_HEADERS=op://AI Agents/Langfuse/auth_header$") {
        Write-Pass "OTEL_EXPORTER_OTLP_HEADERS uses op:// reference"
    } else {
        Write-Fail "OTEL_EXPORTER_OTLP_HEADERS not set to expected op:// reference"
    }
    if ($envContent -match "https://us\.cloud\.langfuse\.com/api/public/otel") {
        Write-Pass "OTEL endpoint = US region"
    } else {
        Write-Fail "OTEL endpoint not pointing at us.cloud.langfuse.com"
    }
    if ($envContent -match "(?m)^OTEL_TRACES_EXPORTER=otlp$") {
        Write-Pass "OTEL_TRACES_EXPORTER=otlp set (traces export reliably)"
    } else {
        Write-Fail "OTEL_TRACES_EXPORTER=otlp missing — traces may not export. Copy the line from .env.example."
    }
    if ($envContent -match "(?m)^OTEL_LOGS_EXPORTER=none$") {
        Write-Pass "OTEL_LOGS_EXPORTER=none set (Langfuse doesn't accept OTLP logs)"
    } else {
        Write-Warn "OTEL_LOGS_EXPORTER not set to 'none' — Claude Code will repeatedly POST to a 404 endpoint at Langfuse"
    }
    if ($envContent -match "(?m)^CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1$") {
        Write-Pass "CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1 set (spans actually emitted)"
    } else {
        Write-Fail "CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1 missing — Claude Code will NOT emit spans, Langfuse Traces tab stays empty. Copy the line from .env.example."
    }
    if ($envContent -match "(?m)^OTEL_METRIC_EXPORT_INTERVAL=\d+$") {
        Write-Pass "OTEL_METRIC_EXPORT_INTERVAL set (short sessions won't lose metrics)"
    } else {
        Write-Fail "OTEL_METRIC_EXPORT_INTERVAL missing — short /command sessions can drop metrics. Copy the line from .env.example."
    }
}

# [5/5] End-to-end OTEL pipeline (op run resolves, Langfuse accepts auth)
Write-Host ""
Write-Host "[5/5] End-to-end OTEL pipeline"
if (-not $script:CriticalFail -and (Test-Path $EnvFile)) {
    Push-Location $RepoRoot
    try {
        $smokeScript = @'
$header = $env:OTEL_EXPORTER_OTLP_HEADERS -replace '^Authorization=', ''
$endpoint = "$($env:OTEL_EXPORTER_OTLP_ENDPOINT)/v1/traces"
$status = curl.exe -s -o NUL -w "%{http_code}" -X POST $endpoint -H "Authorization: $header" -H "Content-Type: application/x-protobuf" --data-binary "@NUL"
Write-Output $status
'@
        $tmpFile = Join-Path $env:TEMP ("preflight_smoke_" + [System.Guid]::NewGuid().ToString("N") + ".ps1")
        [System.IO.File]::WriteAllText($tmpFile, $smokeScript, [System.Text.UTF8Encoding]::new($false))
        $status = (& op run --env-file=.env -- powershell -NoProfile -ExecutionPolicy Bypass -File $tmpFile 2>&1 | Out-String).Trim()
        Remove-Item $tmpFile -ErrorAction SilentlyContinue
        if ($status -match "^(200|400)$") {
            Write-Pass "Langfuse OTEL endpoint returned $status (auth accepted; 400 = empty body rejected = expected)"
        } elseif ($status -match "^(401|403)$") {
            Write-Fail "Langfuse rejected the auth header (HTTP $status). The auth_header value in 1Password may be malformed."
        } else {
            Write-Fail "Unexpected response: $status"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Warn "Skipped - earlier checks failed"
}

# MCP status report (informational, not critical)
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " MCP servers registered in .mcp.json" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
if (Test-Path $McpFile) {
    $mcp = Get-Content $McpFile -Raw | ConvertFrom-Json
    $envContent = if (Test-Path $EnvFile) { Get-Content $EnvFile -Raw } else { "" }
    foreach ($name in $mcp.mcpServers.PSObject.Properties.Name) {
        $cfg = $mcp.mcpServers.$name
        if ($cfg.type -eq "http") {
            Write-Pass "$name (HTTP MCP - browser OAuth on first use)"
        } elseif ($cfg.env) {
            $envVars = $cfg.env.PSObject.Properties.Name
            $missing = @()
            foreach ($v in $envVars) {
                if ($envContent -notmatch "(?m)^$v=") { $missing += $v }
            }
            if ($missing.Count -eq 0) {
                Write-Pass "$name (env vars active in .env)"
            } else {
                Write-Warn ("$name (will fail when invoked - missing: " + ($missing -join ", ") + ")")
            }
        } else {
            Write-Pass "$name (no auth required)"
        }
    }
} else {
    Write-Fail ".mcp.json not found"
}

# Final status
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
if ($script:CriticalFail) {
    Write-Host " RESULT: NOT READY - critical checks failed (see above)" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 1
} else {
    Write-Host " RESULT: READY TO LAUNCH" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Launch with: " -NoNewline
    Write-Host "op run --env-file=.env -- claude" -ForegroundColor Cyan
    Write-Host "Then in Claude Code: " -NoNewline
    Write-Host "/ai-agents-ops" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}
