# Powershell script to export Canvas App solution from Dev environment

# Variables
$solutionName = "UnderwritingWorkbench"
$exportFolder="C:\Users\ripandit\PowerAppsProjects\ExportedSolutions"
$devEnvUrl="https://richasolsdev.crm11.dynamics.com"

# Make sure PAC CLI is available
Write-Host "Checking Power Platform CLI..."
pac --version

# Authenticate (use device-login)
Write-Host "Authenticating to Power Platform environment..."
pac auth create --url $devEnvUrl --name DevEnv

# Create export folder if it doesn't exist
if (!(Test-Path $exportFolder)) {
    New-Item -ItemType Directory -Path $exportFolder | Out-Null
}

# Build full export path
$exportPath = Join-Path -Path $exportFolder -ChildPath "$solutionName.zip"

# Export the solution as unmanaged
Write-Host "Exporting $solutionName from Dev environment..."
pac solution export --name $solutionName --path $exportPath --managed false --overwrite

Write-Host "Export completed successfully!"