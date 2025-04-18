# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands
- Run tests: `./tests.nu` or directly with `go test -v $"(pwd)/..."`
- Run a specific test: Currently no single test runner, uses Go testing
- No explicit lint commands found

## Code Style Guidelines
- Use `#!/usr/bin/env nu` shebang at the beginning of all scripts
- Define functions with `def` or `def --env` for environment-changing functions
- Function parameters: `[param1, param2]` with defaults as `--param = value`
- Variables: Use `let` for constants, `mut` for mutable variables
- String interpolation: `$"text(variable)text"`
- Comments: Use `#` with a space following
- Indentation: 4 spaces
- Error handling: Check conditions and use `exit 1` with descriptive messages
- Function naming: Prefix with `main` for primary commands, followed by action
- Organize related functions within topic-specific scripts (e.g., `kubernetes.nu`)
- When asked to show or get files, open them in VS Code using `code` command
- Always add latest specific version of devbox packages
- Always open files you create or edit in VS Code