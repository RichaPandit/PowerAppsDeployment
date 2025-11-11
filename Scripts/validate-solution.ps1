param (
    [string]$solutionPath = ".\UnpackedSolution",
    [string]$solutionZip = ".\SolutionZip\YourSolution.zip",
    [string]$solutionPackagerPath = ".\tools\SolutionPackager.exe"
)

Write-Host "🔍 Running Power Platform Best Practice Validation..."
$failed = $false

# Check if the solution path exists
if (!(Test-Path $solutionPath)) {
    Write-Warning "⚠️ Solution path '$solutionPath' does not exist. Attempting to unpack solution..."

    if (!(Test-Path $solutionZip)) {
        Write-Error "❌ ERROR: Solution zip file '$solutionZip' not found. Cannot unpack."
        exit 1
    }

    if (!(Test-Path $solutionPackagerPath)) {
        Write-Error "❌ ERROR: SolutionPackager.exe not found at '$solutionPackagerPath'."
        exit 1
    }

    & $solutionPackagerPath /action:Extract /zipfile:$solutionZip /folder:$solutionPath /packagetype:Managed

    if (!(Test-Path $solutionPath)) {
        Write-Error "❌ ERROR: Unpacking failed. '$solutionPath' still does not exist."
        exit 1
    }

    Write-Host "✅ Solution unpacked successfully."
}

# --- 1 Validate Model-Driven Apps ---
try {
    $modelApps = Get-ChildItem "$solutionPath\ModelDrivenApps" -Filter *.xml -Recurse
    foreach ($app in $modelApps) {
        $xml = [xml] (Get-Content $app.FullName)
        $displayName = $xml.appmodule.appmoduleid | Select-Object -ExpandProperty displayname
        if ($displayName -notmatch '^mdl_[A-Z].*') {
            Write-Error "❌ Model-driven app '$displayName' does not follow naming convention (mdl_ prefix required)"
            $failed = $true
        }
    }
} catch {
    Write-Warning "⚠️ Skipping ModelDrivenApps validation: folder not found or unreadable."
}

# --- 2 Validate Tables ---
try {
    $tables = Get-ChildItem "$solutionPath\Entities" -Filter *.xml -Recurse
    foreach ($table in $tables) {
        $xml = [xml] (Get-Content $table.FullName)
        $logicalName = $xml.Entity.LogicalName
        if ($logicalName -notmatch '^ent_[a-z0-9_]+$') {
            Write-Error "❌ Table '$logicalName' does not follow naming convention (ent_ prefix required)"
            $failed = $true
        }
    }
} catch {
    Write-Warning "⚠️ Skipping Entities validation: folder not found or unreadable."
}

# --- 3 Validate Flows ---
try {
    $flows = Get-ChildItem "$solutionPath\Workflows" -Filter *.json -Recurse
    foreach ($flow in $flows) {
        $json = Get-Content $flow.FullName | ConvertFrom-Json
        $name = $json.properties.displayName
        if ($name -notmatch '^flw_[A-Z].*') {
            Write-Error "❌ Flow '$name' does not follow naming convention (flw_ prefix required)"
            $failed = $true
        }
    }
} catch {
    Write-Warning "⚠️ Skipping Workflows validation: folder not found or unreadable."
}

# --- 4 Validate CanvasApps ---
try {
    $canvasApps = Get-ChildItem "$solutionPath\CanvasApps" -Filter *.json -Recurse
    foreach ($app in $canvasApps) {
        if ($app.Name -notmatch '^scr[A-Z].*') {
            Write-Error "❌ Canvas screen '$($app.Name)' does not follow naming convention (scr prefix required)"
            $failed = $true
        }
    }
} catch {
    Write-Warning "⚠️ Skipping CanvasApps validation: folder not found or unreadable."
}

# --- Final Result ---
if ($failed) {
    Write-Error "❌ Validation failed. Fix naming issues before deployment."
    exit 1
} else {
    Write-Host "✅ All naming conventions validated successfully!"
}