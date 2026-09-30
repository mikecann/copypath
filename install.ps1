# Install thin Windows and Git Bash launchers; source stays in this clone.
param([string]$ToolsDir = 'C:\dev\tools')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install-lib.ps1')
$launchers = Get-CopypathLaunchers -RepoDir $PSScriptRoot
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
foreach ($name in $launchers.Keys) {
    $destination = Join-Path $ToolsDir $name
    Set-Content -LiteralPath $destination -Value $launchers[$name] -Encoding ASCII
    Write-Host "Installed $destination" -ForegroundColor Green
}
Write-Host "Keep this clone in place. Add '$ToolsDir' to PATH if needed, then open a new terminal."
