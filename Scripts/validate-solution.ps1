param (
    [string]$solutionPath = ".\UnpackedSolution"
)

Write-Host "Running Power Platform Best Practice Validation..."

# --- 1 Validate Model-Driven Apps ---
$modelApps = Get-ChildItem "$solutionPath\ModelDrivenApps" -Filter *.xml -Recurse
foreach ($app in $modelApps) {
    $xml = [xml] (Get-Content $app.FullName)
    $displayName = $xml.appmodule.appmoduleid | Select-Object -ExpandProperty displayname
    if ($displayName -notmatch '^mdl_[A-Z].*') {
        Write-Error "Model-driven app '$displayName' does not follow naming convention (mdl_ prefix required)"
        $failed = $true
    }
}

# --- 2 Validate Tables ---
$tables = Get-ChildItem "$solutionPath\Entities" -Filter *.xml -Recurse
foreach ($table in $tables) {
    $xml = [xml] (Get-Content $table.FullName)
    $logicalName = $xml.Entity.LogicalName
    if ($logicalName -notmatch '^ent_[a-z0-9_]+$') {
        Write-Error "Table '$logicalName' does not follow naming convention (ent_ prefix required)"
        $failed = $true
    }
}

# --- 3 Validate Flows ---
$flows = Get-ChildItem "$solutionPath\Workflows" -Filter *.json -Recurse
foreach ($flow in $flows) {
    $json = Get-Content $flow.FullName | ConvertFrom-Json
    $name = $json.properties.displayName
    if ($name -notmatch '^flw_[A-Z].*') {
        Write-Error "Flow '$name' does not follow naming convention (flw_ prefix required)"
        $failed = $true
    }
}

# --- 4 Validate CanvasApps ---
$canvasApps = Get-ChildItem "$solutionPath\CanvasApps" -Filter *.json -Recurse
foreach ($app in $canvasApps) {
    if ($app.Name -notmatch '^scr[A-Z].*') {
        Write-Error "Canvas screen '$($app.Name)' does not follow naming convention (scr prefix required)"
        $failed = $true
    }
}

if ($failed) {
    Write-Error "Validation failed. Fix naming issues before deployment."
    exit 1
} else {
    Write-Host "All naming conventions validated successfully!"
}