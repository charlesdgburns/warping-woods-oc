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
$logFile = Join-Path $logDir "test_results_$timestamp.log"

Write-Host "=== Running GUT tests ==="
Write-Host "Binary: $godot"
Write-Host "Project: $proj"
Write-Host "Config: res://tests/.gutconfig.json"
Write-Host "Log: $logFile"
Write-Host ""

$output = & $godot "-s" "res://addons/gut/gut_cmdln.gd" "--path" $proj "-gconfig=res://tests/.gutconfig.json" "-gexit" 2>&1
$exitCode = $LASTEXITCODE

$output | Out-File -FilePath $logFile -Encoding utf8

# Display output
Write-Host $output

# Parse totals line (e.g. "Totals: 10 passed, 0 failed, 0 pending, 0 risky")
$totalsLine = $output | Select-String -Pattern "Totals:" | Select-Object -Last 1
$failedCount = 0
$errorLines = @()
$allPassed = $false

if ($totalsLine) {
    $lineText = $totalsLine.Line
    Write-Host "`n$lineText"
    
    # Try to extract "X failed"
    if ($lineText -match "(\d+)\s+failed") {
        $failedCount = [int]$Matches[1]
    }
    
    # Also extract "X passed" to confirm all pass
    if ($lineText -match "(\d+)\s+passed") {
        $passedCount = [int]$Matches[1]
    }
    
    if ($failedCount -eq 0) {
        $allPassed = $true
    }
} else {
    # No totals line means GUT didn't finish - check for errors
    foreach ($line in $output) {
        if ($line -match "(ERROR|SCRIPT ERROR|FAIL|Assertion Error)") {
            $errorLines += $line
        }
    }
    if ($errorLines.Count -gt 0) {
        $failedCount = $errorLines.Count
    } else {
        # Unknown failure
        $failedCount = 1
        $errorLines += "GUT did not produce a 'Totals' line. Check the log for details."
    }
}

Write-Host ""
if ($allPassed) {
    Write-Host "=== All tests passed ===" -ForegroundColor Green
    Write-Host "Full output written to: $logFile"
    exit 0
} else {
    Write-Host "=== $failedCount test failure(s) detected ===" -ForegroundColor Red
    foreach ($el in $errorLines) {
        Write-Host "  $el" -ForegroundColor Yellow
    }
    Write-Host "Full output written to: $logFile" -ForegroundColor Yellow
    exit 1
}
