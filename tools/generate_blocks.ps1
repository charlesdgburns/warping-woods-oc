# Standalone encounter block generator
# Produces JSON files matching the format in implementation.md §10.4
# Matches tools/block_generator.gd (same seed, connectivity rules)

$seed = 42
$blockCount = 20
$outputDir = Join-Path $PSScriptRoot "..\resources\blocks"

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$rng = [System.Random]::new($seed)
$neighbourOffsets = @((0,-1), (0,1), (-1,0), (1,0))

function Test-Connected4Dir($grid) {
    # Find first non-unwalkable tile
    $sx = -1; $sy = -1
    for ($x = 0; $x -lt 3 -and $sx -eq -1; $x++) {
        for ($y = 0; $y -lt 3 -and $sx -eq -1; $y++) {
            if ($grid[$x][$y] -ne "unwalkable") { $sx = $x; $sy = $y }
        }
    }
    if ($sx -eq -1) { return $false }

    $visited = New-Object 'bool[,]' 3,3
    $stack = New-Object 'System.Collections.Generic.Stack[tuple[int,int]]'
    $stack.Push([tuple[int,int]]::new($sx, $sy))
    $visited[$sx, $sy] = $true

    while ($stack.Count -gt 0) {
        $c = $stack.Pop()
        foreach ($off in $neighbourOffsets) {
            $nx = $c.Item1 + $off[0]; $ny = $c.Item2 + $off[1]
            if ($nx -lt 0 -or $nx -gt 2 -or $ny -lt 0 -or $ny -gt 2) { continue }
            if ($visited[$nx, $ny]) { continue }
            if ($grid[$nx][$ny] -eq "unwalkable") { continue }
            $visited[$nx, $ny] = $true
            $stack.Push([tuple[int,int]]::new($nx, $ny))
        }
    }

    for ($x = 0; $x -lt 3; $x++) {
        for ($y = 0; $y -lt 3; $y++) {
            if ($grid[$x][$y] -ne "unwalkable" -and -not $visited[$x, $y]) { return $false }
        }
    }
    return $true
}

function New-EncounterBlock($rng) {
    $grid = @(
        @("walkable", "walkable", "walkable"),
        @("walkable", "walkable", "walkable"),
        @("walkable", "walkable", "walkable")
    )

    # Build and shuffle position list
    $positions = [System.Collections.ArrayList]@()
    for ($x = 0; $x -lt 3; $x++) {
        for ($y = 0; $y -lt 3; $y++) {
            $positions.Add(@($x, $y)) | Out-Null
        }
    }
    # Fisher-Yates
    for ($i = $positions.Count - 1; $i -gt 0; $i--) {
        $j = $rng.Next(0, $i + 1)
        $tmp = $positions[$i]; $positions[$i] = $positions[$j]; $positions[$j] = $tmp
    }

    # Place 2 unwalkable tiles with connectivity check
    $unwalkablePlaced = 0
    foreach ($pos in $positions) {
        if ($unwalkablePlaced -ge 2) { break }
        $grid[$pos[0]][$pos[1]] = "unwalkable"
        if (Test-Connected4Dir $grid) {
            $unwalkablePlaced++
        } else {
            $grid[$pos[0]][$pos[1]] = "walkable"
        }
    }
    if ($unwalkablePlaced -lt 2) { return $null }

    # Collect walkable and pick one for encounter
    $walkablePositions = [System.Collections.ArrayList]@()
    for ($x = 0; $x -lt 3; $x++) {
        for ($y = 0; $y -lt 3; $y++) {
            if ($grid[$x][$y] -eq "walkable") { $walkablePositions.Add(@($x, $y)) | Out-Null }
        }
    }
    if ($walkablePositions.Count -eq 0) { return $null }

    $ep = $walkablePositions[$rng.Next(0, $walkablePositions.Count)]
    $grid[$ep[0]][$ep[1]] = "encounter"

    # Build tiles array
    $tiles = @()
    for ($x = 0; $x -lt 3; $x++) {
        for ($y = 0; $y -lt 3; $y++) {
            $tiles += @{
                type = $grid[$x][$y]
                pos = @($x, $y)
                has_encounter_token = ($grid[$x][$y] -eq "encounter")
            }
        }
    }

    return @{ id = ""; type = "encounter"; tiles = $tiles }
}

$generated = 0; $attempts = 0; $maxAttempts = 500
while ($generated -lt $blockCount -and $attempts -lt $maxAttempts) {
    $attempts++
    $block = New-EncounterBlock $rng
    if (-not $block) { continue }

    $generated++
    $blockId = "encounter_{0:D2}" -f $generated
    $block.id = $blockId

    $path = Join-Path $outputDir "$blockId.json"
    $json = $block | ConvertTo-Json -Depth 4
    Set-Content -Path $path -Value $json -Encoding UTF8
    Write-Host "Wrote $path"
}

Write-Host "Generated $generated encounter blocks ($attempts attempts)"
