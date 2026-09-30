# Agent guidance for copypath

Small clipboard CLI for Windows and macOS. Source lives at this repo's root.

## Working on the tool

- Keep logic here. `C:\dev\tools` holds generated launchers, never source.
- Use test-first development for non-trivial changes. Add or update the test
  before changing behaviour, then rerun the relevant tests.
- Test before committing. Run `pwsh -NoProfile -File tests/run-tests.ps1` and,
  on macOS, `python3 -m unittest discover -s tests -v`.
- Parse every `.ps1` with PowerShell's
  `[System.Management.Automation.Language.Parser]::ParseFile` before committing.
- Smoke-test the actual tool directly in PowerShell on Windows and via
  `./copypath` on macOS. Verify the clipboard and exit code on the target OS.
  Automated tests replace the clipboard writer to avoid changing user data.
- Batch launchers must be ASCII. Use `-Encoding ASCII` when generating them.
- Re-run `install.ps1` or `bash install.sh` after moving this clone. Editing
  the tool does not need a reinstall because launchers point to the live files.
- Keep large binaries out of Git. This tool currently has no external binary
  downloads, API keys, `.env` settings, or `deps.ps1`.
- If dependencies are added, a root `deps.ps1` must be self-contained,
  idempotent, check before installing, and print clear output. The Windows
  installer must then call it. Do not add dependencies just for the split.
- Uninstall must remove only this tool's launchers. Preserve other tools,
  shared directories, PATH entries, and any shared Explorer menus.

## Platform details

- `copypath.ps1` uses PowerShell provider resolution, falling back to an
  unresolved provider path for paths that do not exist, then `Set-Clipboard`.
- `copypath` is the macOS Bash launcher. It uses Python 3 for path normalization
  and `pbcopy` for the clipboard. It does not require PowerShell on macOS.
- `install.ps1` creates `copypath.bat` and a Git Bash wrapper in `C:\dev\tools`
  by default. `uninstall.ps1` removes matching launchers only.
- `install.sh` creates a symlink in `~/.local/bin` by default.
- This is a terminal tool, with no GUI, taskbar shortcuts, or Explorer verbs.
