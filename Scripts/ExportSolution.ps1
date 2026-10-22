param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$EnvironmentUrl,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SolutionName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExportPath
)

$ErrorActionPreference = "Stop"

function Invoke-Pac {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    & pac @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "PAC $Operation failed with exit code $LASTEXITCODE."
    }
}

$resolvedExportPath = [System.IO.Path]::GetFullPath($ExportPath)
$exportDirectory = Split-Path -Parent $resolvedExportPath

if (!(Test-Path -LiteralPath $exportDirectory)) {
    New-Item -ItemType Directory -Path $exportDirectory -Force | Out-Null
}

Write-Host "Checking Power Platform CLI..."
Invoke-Pac -Arguments @("--version") -Operation "version check"

Write-Host "Authenticating to Power Platform environment..."
Invoke-Pac -Arguments @("auth", "create", "--url", $EnvironmentUrl, "--name", "DevEnv") -Operation "authentication"

Write-Host "Exporting $SolutionName from the specified environment..."
Invoke-Pac -Arguments @("solution", "export", "--name", $SolutionName, "--path", $resolvedExportPath, "--managed", "false", "--overwrite") -Operation "solution export"

Write-Host "Export completed successfully!"