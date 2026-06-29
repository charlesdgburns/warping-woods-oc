param(
    [string]$GodotBin = "",
    [string]$ProjectDir = ""
)

# Self-bypass bootstrap: re-run with ExecutionPolicy Bypass when restricted
if (-not $env:CAPTURE_BYPASSED -and $PSExecutionPolicyPreference -in 'Restricted','Undefined') {
    $env:CAPTURE_BYPASSED = '1'
    $bootArgs = @('-ExecutionPolicy', 'Bypass', '-NoProfile', '-File', $PSCommandPath)
    if ($GodotBin) { $bootArgs += @('-GodotBin', $GodotBin) }
    if ($ProjectDir) { $bootArgs += @('-ProjectDir', $ProjectDir) }
    & powershell.exe $bootArgs
    $ec = $LASTEXITCODE
    Remove-Item Env:CAPTURE_BYPASSED -ErrorAction SilentlyContinue
    exit $ec
}

function Find-GodotBinary {
    param([string]$SearchPath)
    if ($SearchPath -and (Test-Path -LiteralPath $SearchPath)) {
        return $SearchPath
    }

    $candidates = @(
        "C:\Users\owner\Coding\godot\Godot_v4.7-stable_win64_console.exe",
        "C:\Users\owner\Coding\godot\Godot_v4.7-stable_win64.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) {
            return $c
        }
    }

    $which = Get-Command "godot" -ErrorAction SilentlyContinue
    if ($which) {
        return $which.Source
    }

    return $null
}

function Find-ProjectDir {
    param([string]$Hint)
    if ($Hint -and (Test-Path -LiteralPath $Hint -PathType Container)) {
        return $Hint
    }
    $proj = Get-Location
    if (Test-Path -LiteralPath (Join-Path $proj "project.godot")) {
        return $proj
    }
    return $null
}

$godot = Find-GodotBinary $GodotBin
if (-not $godot) {
    Write-Error "Godot binary not found. Specify -GodotBin or install Godot."
    exit 1
}

$proj = Find-ProjectDir $ProjectDir
if (-not $proj) {
    Write-Error "Project directory not found (no project.godot). Specify -ProjectDir."
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir = Join-Path $proj "debug"
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
# Keep only the latest capture — clear old logs
Remove-Item -Path (Join-Path $logDir "*.log") -Force -ErrorAction SilentlyContinue
$logFile = Join-Path $logDir "parse_errors_$timestamp.log"

Write-Host "=== Capturing Godot parse errors ==="
Write-Host "Binary: $godot"
Write-Host "Project: $proj"
Write-Host "Log: $logFile"
Write-Host ""

$output = & $godot "--path" $proj "--headless" "--quit" 2>&1
$exitCode = $LASTEXITCODE

$output | Out-File -FilePath $logFile -Encoding utf8

$errorCount = 0
$errorLines = @()
foreach ($line in $output) {
    if ($line -match "(Parser Error|Parse Error|ERROR|SCRIPT ERROR)") {
        $errorCount++
        $errorLines += $line
    }
}

Write-Host ""
if ($errorCount -gt 0) {
    Write-Host "=== $errorCount error(s) detected ===" -ForegroundColor Red
    foreach ($el in $errorLines) {
        Write-Host "  $el" -ForegroundColor Yellow
    }
    Write-Host "Full output written to: $logFile" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "=== No errors detected ===" -ForegroundColor Green
    Write-Host "Full output written to: $logFile"
    exit 0
}
