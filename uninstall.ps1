# Remove only launchers still pointing at this clone. Leave other tools and PATH alone.
param([string]$ToolsDir = 'C:\dev\tools')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'install-lib.ps1')
$launchers = Get-CopypathLaunchers -RepoDir $PSScriptRoot
# The batch stub identifies the clone; the generic Bash wrapper must stay if
# another clone has replaced that stub. Check the batch file first.
foreach ($name in @('copypath.bat', 'copypath')) {
    $destination = Join-Path $ToolsDir $name
    if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { continue }
    $content = Get-Content -LiteralPath $destination -Raw
    # Set-Content adds a final newline. Normalize line endings across PS versions.
    if ($content.TrimEnd("`r", "`n").Replace("`r`n", "`n") -ceq $launchers[$name].Replace("`r`n", "`n")) {
        Remove-Item -LiteralPath $destination
        Write-Host "Removed $destination" -ForegroundColor Green
    } else {
        Write-Warning "Keeping modified launcher: $destination"
        if ($name -eq 'copypath.bat') { return }
    }
}
