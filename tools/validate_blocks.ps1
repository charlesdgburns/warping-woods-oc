$errors = 0
$outputDir = "C:\Users\owner\Coding\warping-woods-oc\resources\blocks"

# Check hand-designed blocks
foreach ($name in @("summoning", "shop", "warp_wizard")) {
    $path = Join-Path $outputDir "$name.json"
    $data = Get-Content $path -Raw | ConvertFrom-Json
    $unwalk = @($data.tiles | Where-Object { $_.type -eq "unwalkable" }).Count
    $enc = @($data.tiles | Where-Object { $_.type -eq "encounter" }).Count
    $walk = @($data.tiles | Where-Object { $_.type -eq "walkable" }).Count
    $tiles = $data.tiles.Count
    if ($tiles -ne 9) { Write-Host "ERROR $name tiles=$tiles (expected 9)"; $errors++ }
    if ($name -eq "warp_wizard" -and $unwalk -ne 2) { Write-Host "ERROR $name unwalkable=$unwalk (expected 2)"; $errors++ }
    if ($name -eq "warp_wizard" -and $enc -ne 0) { Write-Host "ERROR $name encounter=$enc (expected 0)"; $errors++ }
    if (($name -eq "summoning" -or $name -eq "shop") -and $unwalk -ne 0) { Write-Host "ERROR $name unwalkable=$unwalk (expected 0)"; $errors++ }
    Write-Host "OK $name.json (walk=$walk, unwalk=$unwalk, enc=$enc)"
}

# Check generated encounter blocks
for ($i = 1; $i -le 20; $i++) {
    $id = "encounter_{0:D2}" -f $i
    $path = Join-Path $outputDir "$id.json"
    $data = Get-Content $path -Raw | ConvertFrom-Json
    $unwalk = @($data.tiles | Where-Object { $_.type -eq "unwalkable" }).Count
    $enc = @($data.tiles | Where-Object { $_.type -eq "encounter" }).Count
    $walk = @($data.tiles | Where-Object { $_.type -eq "walkable" }).Count
    $tiles = $data.tiles.Count
    if ($tiles -ne 9) { Write-Host "ERROR $id tiles=$tiles (expected 9)"; $errors++ }
    if ($enc -ne 1) { Write-Host "ERROR $id encounter=$enc (expected 1)"; $errors++ }
    if ($unwalk -ne 2) { Write-Host "ERROR $id unwalkable=$unwalk (expected 2)"; $errors++ }
    if ($walk -ne 6) { Write-Host "ERROR $id walkable=$walk (expected 6)"; $errors++ }
    Write-Host "OK $id.json (walk=$walk, unwalk=$unwalk, enc=$enc)"
}

Write-Host "`nTotal errors: $errors"
if ($errors -gt 0) { exit 1 }
