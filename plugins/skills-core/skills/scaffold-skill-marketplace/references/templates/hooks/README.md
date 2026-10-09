# Hooks

Hooks let this marketplace run scripts at Claude Code lifecycle events. They are
wired in `hooks.json` and reference scripts under `hooks/scripts/` via the
`${CLAUDE_PLUGIN_ROOT}` variable (which Claude Code sets to this plugin's root).

## Current hooks

| Event | Script | Purpose |
|-------|--------|---------|
| `UserPromptSubmit` | `scripts/recommend-skills.sh` | Suggests relevant skills based on the user's prompt. |

## Adding a hook

1. Add a script under `hooks/scripts/` (kebab-case name, `set -euo pipefail`, macOS `bash 3.2`-safe).
2. Wire it in `hooks.json` under the appropriate event (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`, ...).
3. Use `${CLAUDE_PLUGIN_ROOT}` for all paths so the hook works wherever the plugin is installed.

## Hook I/O

- Hook scripts receive a JSON payload on **stdin** (fields vary by event; `UserPromptSubmit` includes `prompt`).
- **stdout** from `UserPromptSubmit` is injected into the model's context.
- Exit code `2` from a `PreToolUse` hook blocks the tool call and feeds stderr back to Claude; any other
  non-zero exit is a non-blocking error. Keep exits `0` unless you intend to block.
