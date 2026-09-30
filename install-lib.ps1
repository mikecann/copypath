function Get-CopypathLaunchers {
    param([string]$RepoDir)

    # An ASCII batch stub cannot represent a clone path containing Unicode.
    if ($RepoDir -match '[^\x00-\x7F]') {
        throw 'Keep the Windows clone at an ASCII path so the batch launcher can find it.'
    }
    $scriptPath = Join-Path $RepoDir 'copypath.ps1'
    $bat = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "$scriptPath" %*
"@
    $bash = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/copypath.bat" "$@"
'@
    return @{ 'copypath.bat' = $bat; 'copypath' = $bash }
}
