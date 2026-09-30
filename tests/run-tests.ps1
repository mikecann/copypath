$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ('copypath-tests-' + [guid]::NewGuid())
$toolsDir = Join-Path $temp 'tools with spaces'
$checks = 0

function Assert-Equal($Actual, $Expected, [string]$Message) {
    if ($Actual -cne $Expected) { throw "$Message. Expected '$Expected', got '$Actual'." }
    $script:checks++
}

# Exercise the actual script without changing the user's clipboard.
$clipboardCapture = @{ Value = $null }
function Set-Clipboard { param($Value) $clipboardCapture.Value = $Value }

try {
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    Push-Location $temp
    try {
        & (Join-Path $repo 'copypath.ps1')
        Assert-Equal $clipboardCapture.Value $PWD.Path 'Default copies the current directory'
        $file = Join-Path $temp 'file with spaces.txt'
        Set-Content -LiteralPath $file -Value 'test'
        & (Join-Path $repo 'copypath.ps1') 'file with spaces.txt'
        Assert-Equal $clipboardCapture.Value $file 'Relative files resolve to absolute paths'
        & (Join-Path $repo 'copypath.ps1') $temp
        Assert-Equal $clipboardCapture.Value $temp 'Absolute directories are preserved'
        & (Join-Path $repo 'copypath.ps1') 'missing folder/file.txt'
        $missing = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('missing folder/file.txt')
        Assert-Equal $clipboardCapture.Value $missing 'Missing paths still resolve'
    } finally { Pop-Location }

    $other = Join-Path $toolsDir 'other-tool.bat'
    Set-Content -LiteralPath $other -Value 'leave me alone'
    & (Join-Path $repo 'install.ps1') -ToolsDir $toolsDir
    $batPath = Join-Path $toolsDir 'copypath.bat'
    $bashPath = Join-Path $toolsDir 'copypath'
    $bat = Get-Content -LiteralPath $batPath -Raw
    $bash = Get-Content -LiteralPath $bashPath -Raw
    $target = Join-Path $repo 'copypath.ps1'
    Assert-Equal ($bat.Contains('powershell -NoProfile -ExecutionPolicy Bypass -File "' + $target + '" %*')) $true 'Batch stub targets this clone and forwards arguments'
    Assert-Equal ($bash.Contains('exec "$SCRIPT_DIR/copypath.bat" "$@"')) $true 'Git Bash wrapper forwards arguments'
    foreach ($path in @($batPath, $bashPath)) {
        Assert-Equal (@([System.IO.File]::ReadAllBytes($path) | Where-Object { $_ -gt 127 }).Count) 0 'Generated stubs are ASCII'
    }
    & (Join-Path $repo 'install.ps1') -ToolsDir $toolsDir
    Assert-Equal (Get-Content -LiteralPath $batPath -Raw) $bat 'Reinstallation is idempotent'
    & (Join-Path $repo 'uninstall.ps1') -ToolsDir $toolsDir
    Assert-Equal (Test-Path -LiteralPath $batPath) $false 'Uninstall removes the batch stub'
    Assert-Equal (Test-Path -LiteralPath $bashPath) $false 'Uninstall removes the Bash stub'
    Assert-Equal (Test-Path -LiteralPath $other) $true 'Other tools survive uninstall'
    & (Join-Path $repo 'uninstall.ps1') -ToolsDir $toolsDir

    & (Join-Path $repo 'install.ps1') -ToolsDir $toolsDir
    Set-Content -LiteralPath $batPath -Value 'another install owns this now'
    & (Join-Path $repo 'uninstall.ps1') -ToolsDir $toolsDir
    Assert-Equal (Get-Content -LiteralPath $batPath -Raw).Trim() 'another install owns this now' 'Uninstall preserves replaced launchers'
    Assert-Equal (Test-Path -LiteralPath $bashPath) $true 'A replaced batch stub keeps its companion wrapper'
    Write-Host "Passed $checks PowerShell checks."
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}
