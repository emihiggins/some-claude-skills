---
name: scaffold-skill-marketplace
description: >
  Scaffold a new git repository that acts as a shareable Claude Code plugin
  marketplace for skills, agents, and hooks. Use when asked to "create a skill
  marketplace", "scaffold a claude code marketplace repo", "set up a shared
  skills repo", "bootstrap a claude plugin repo", or "make a repo others can
  install skills from". NOT for authoring an individual skill inside an existing
  repo (create skills/<name>/SKILL.md directly), and NOT for publishing or
  releasing an existing marketplace.
author: emhiggins
version: 1.0.0
argument-hint: "[target-dir]"
---

# Scaffold Skill Marketplace

Generate a new repository structured as a Claude Code **plugin marketplace** — a
single repo that exposes one plugin whose `skills/`, `agents/`, and `hooks/` are
auto-discovered, plus a validation linter, PR-scope CI, and semantic-release
auto-versioning. The generated repo has no organization-specific content.

## Prerequisites

- `bash` (macOS `bash 3.2` is fine).
- `jq` — only needed later to run the generated `update-plugin-versions.sh`. Not
  required to scaffold.
- The scaffolder writes files only; it never runs `git` or contacts a remote.

## Workflow

1. **Gather parameters.** Ask the user only for what is missing; everything but
   `--name` has a sensible default.
   - `--name` (required): the marketplace id, kebab-case (e.g. `my-team-skills`).
   - `--plugin-name` (default: same as `--name`).
   - `--description` (default: derived from the name).
   - `--owner-name`, `--owner-email` (defaults: placeholders).
   - `--version` (default: `0.1.0`).
   - `--target-dir` (default: `./<name>`).

2. **Run the generator:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/scaffold-skill-marketplace}/scripts/scaffold.sh" \
     --name <name> \
     --owner-name "<Owner>" \
     --owner-email "<email>" \
     --target-dir <path>
   ```
   Pass `--force` only if the target dir already has content the user wants replaced.

3. **Validate the sample skill** to confirm the scaffold is healthy:
   ```bash
   cd <target-dir> && bash scripts/validate-skill.sh skills/example-tool-skill
   ```

4. **Report next steps** to the user (the generator also prints these):
   - `git init && git add -A && git commit -m "chore: initial marketplace scaffold"`
   - Create the GitHub repo and push (leave this to the user).
   - Test locally: `claude --plugin-dir "$(pwd)"` then `/skills`.
   - Consumers register the marketplace in their `.claude/settings.json` under
     `extraKnownMarketplaces` + `enabledPlugins` (see the generated `README.md`).

## What gets generated

```
<repo>/
├── .claude-plugin/{marketplace.json, plugin.json}   # strict:false auto-discovery
├── .github/workflows/{release.yml, pr-scope-check.yml}, PULL_REQUEST_TEMPLATE.md
├── hooks/{hooks.json, scripts/recommend-skills.sh, README.md}
├── skills/example-tool-skill/SKILL.md               # working sample
├── scripts/{validate-skill.sh, update-plugin-versions.sh}
├── .releaserc.json, CLAUDE.md, CONTRIBUTING.md, README.md, .gitignore
```

## Error Handling

- **Missing `--name`** or a non-kebab-case name: the generator exits with a clear
  message. Ask the user for a valid kebab-case id and re-run.
- **Non-empty target dir**: the generator refuses unless `--force` is passed.
  Confirm with the user before using `--force` — it overwrites files.
- **Templates not found**: the generator expects templates at
  `references/templates/` relative to itself; if it errors here, the skill install
  is incomplete — re-check the skill directory.

## Customization

The generated files are plain templates in `references/templates/`. To change what
every scaffold produces (add a category prefix, a hook, a CI step), edit those
template files — `{{MARKETPLACE_NAME}}`, `{{PLUGIN_NAME}}`, `{{DESCRIPTION}}`,
`{{OWNER_NAME}}`, `{{OWNER_EMAIL}}`, and `{{VERSION}}` are substituted at scaffold
time.
