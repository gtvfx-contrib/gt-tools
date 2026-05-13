# Update PYTHONPATH Script

Automatically discovers all git repositories in the workspace and adds their `py` subdirectories to the PYTHONPATH environment variable.

## Features

- **Recursive Search**: Finds all git repositories (directories with `.git`) in the workspace
- **Smart Detection**: Only adds `py` subdirectories that exist
- **Duplicate Prevention**: Checks existing PYTHONPATH and skips already-added paths
- **Flexible**: Can update current session or make permanent changes

## Usage

### PowerShell

```powershell
# Update PYTHONPATH for current session only
.\update_pythonpath.ps1

# Update PYTHONPATH permanently (User-level)
.\update_pythonpath.ps1 -Permanent

# Show verbose output with all paths
.\update_pythonpath.ps1 -Verbose

# Combine options
.\update_pythonpath.ps1 -Permanent -Verbose
```

### Batch File (Windows CMD)

```batch
REM Update PYTHONPATH for current session
update_pythonpath.bat

REM With permanent flag (dash optional; also accepts 'permanent')
update_pythonpath.bat -Permanent
update_pythonpath.bat permanent

REM Show help (supports -h, --help, help, ?)
update_pythonpath.bat -h
```

## Parameters

- **`-Permanent`**: Updates the User-level environment variable permanently. Without this flag, changes only affect the current PowerShell session.
- **`-Verbose`**: Shows detailed output including current PYTHONPATH, all discovered repositories, and final PYTHONPATH.
- **`-WorkspaceRoot`**: Specify a custom workspace root (default: parent of tools directory)

Note: The `update_pythonpath.bat` wrapper accepts friendly forms of these flags (e.g., `permanent`, `verbose` — case-insensitive) without a leading dash, and recognizes `-h`, `--help`, `help`, or `?` to display usage and exit.

## Example Output

```
Scanning workspace: \\THO_CLOUD\gavyn\repo

Searching for git repositories...
Found 13 git repositories
  + Adding: \\THO_CLOUD\gavyn\repo\python_packages\py
  + Adding: \\THO_CLOUD\gavyn\repo\sudoku_solver\py
  + Adding: \\THO_CLOUD\gavyn\repo\tools\py
  + Adding: \\THO_CLOUD\gavyn\repo\robinhood\py
  + Adding: \\THO_CLOUD\gavyn\repo\coinbase\py

Updating PYTHONPATH...
[OK] PYTHONPATH updated for current session

Added 5 new path(s) to PYTHONPATH

Done!
```

## How It Works

1. Scans the workspace root directory recursively
2. Identifies all git repositories (directories containing `.git`)
3. Checks each repository for a `py` subdirectory
4. Compares found paths with existing PYTHONPATH entries
5. Adds only new, unique paths to PYTHONPATH
6. Updates the environment variable (current session or permanent)

## Related

- See [update_path](update_path_README.md) for the companion script that scans repositories for `bin/` directories and adds them to your PATH.

## Notes

- **Session vs Permanent**: By default, changes only affect the current PowerShell session. Use `-Permanent` to update the User-level registry setting.
- **Execution Policy**: If you get an execution policy error, run: `powershell -ExecutionPolicy Bypass -File .\update_pythonpath.ps1`
- **Path Normalization**: All paths are normalized to full paths and trailing backslashes are removed for consistent comparison
- **No Duplicates**: Running the script multiple times won't create duplicate entries

## Troubleshooting

**Script won't run (execution policy error)**
```powershell
# One-time bypass
powershell -ExecutionPolicy Bypass -File .\update_pythonpath.ps1

# Or use the batch file which handles this automatically
.\update_pythonpath.bat
```

**Changes not persisting**
- Use the `-Permanent` flag to write to User-level environment variables
- Restart your terminal/IDE after making permanent changes
- Check if you have permissions to modify environment variables

**Not finding repositories**
- Ensure directories contain a `.git` folder (git initialized)
- Check that `py` subdirectory exists in each repository
- Use `-Verbose` to see what's being discovered
