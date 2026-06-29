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

$screenDir = Join-Path $proj "debug\screenshots"
if (-not (Test-Path -LiteralPath $screenDir)) {
    New-Item -ItemType Directory -Path $screenDir -Force | Out-Null
}

Write-Host "=== Capturing screenshots ==="
Write-Host "Binary: $godot"
Write-Host "Project: $proj"
Write-Host "Output: $screenDir"
Write-Host ""

$output = & $godot "--path" $proj "--capture-screenshots" 2>&1
$exitCode = $LASTEXITCODE

Write-Host ""

$screenshots = Get-ChildItem -Path $screenDir -Filter "*.png" | Sort-Object Name
if ($screenshots.Count -gt 0) {
    Write-Host "=== $($screenshots.Count) screenshot(s) captured ===" -ForegroundColor Green
    foreach ($s in $screenshots) {
        Write-Host "  $($s.Name)" -ForegroundColor Cyan
    }
} else {
    Write-Host "=== No screenshots found ===" -ForegroundColor Red
}

if ($exitCode -ne 0) {
    Write-Host "Godot exited with code: $exitCode" -ForegroundColor Yellow
}

exit $exitCode
