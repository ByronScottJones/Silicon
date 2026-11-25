---
title: "Bash / Zsh"
description: "Open this file only when writing or modifying Bash or Zsh scripts."
applies_to: ["*.sh", "*.bash", "*.zsh"]
---

# Bash / Zsh

Open this file only when writing or modifying Bash or Zsh scripts. General rules stay in the root `AGENTS.md`.

## Configuration

- Source configuration only after checking that the file exists and is trusted.
- Prefer `${XDG_CONFIG_HOME:-$HOME/.config}/<app-name>/` for user configuration when the application follows XDG conventions.
- Keep secrets out of sourced files that are committed to version control.

## Formatting & Linting

- Formatter: `shfmt` (authoritative — never suggest conflicting style).
- Linter: `shellcheck`.
- Bash scripts must pass `shellcheck` without disabling rules unless there's a documented reason.

## Error Handling

- All scripts: `set -euo pipefail` at the top.
- Quote all variable expansions: `"${var}"`.
- Check exit codes explicitly when a command can fail meaningfully.
- No `eval` unless absolutely necessary and inputs are fully controlled.

## Testing

- Use `bats-core` for non-trivial scripts.
- At minimum, test with known inputs/outputs via a `test` target in a Makefile.

## Conventions

- Scripts that accept arguments follow `cli.md`: provide `-h`/`--help`, reject
  unknown arguments with exit code `2`, and accept `--` to end options.
- Prefer functions over long linear scripts.
- Use `local` for all variables inside functions.
- Avoid parsing `ls` output — use globs or `find`.
- Shebang line: `#!/usr/bin/env bash` or `#!/usr/bin/env zsh`.

## Code Generation Defaults

- Bash: `#!/usr/bin/env bash` then `set -euo pipefail`.
- Zsh: `#!/usr/bin/env zsh` then `set -euo pipefail`.
