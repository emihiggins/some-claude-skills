# Authoring conventions

This repository is a **Claude Code plugin marketplace**. It publishes two plugins,
each under `plugins/<plugin>/`:

- `skills-core` — atomic, framework-free skills plus one skill-recommender hook.
- `feature-builder` — the multi-agent feature workflow, its agents, and its
  workflow-enforcement hooks. Opt-in.

Each plugin's skills, agents, and hooks are auto-discovered because
`.claude-plugin/marketplace.json` sets `"strict": false` on every plugin entry.
Adding a skill is just adding a directory and merging — no manifest edit required.

## Skill layout

- Skills live at `plugins/<plugin>/skills/<name>/SKILL.md`. Each plugin's `skills/`
  tree is **flat, one level deep** — Claude Code scans `skills/*/SKILL.md` under the
  plugin root, so do **not** nest skills.
- No `README.md` inside a skill folder — `SKILL.md` is the single entry point.
- Optional subdirectories per skill: `references/` (deep-dive docs and templates
  loaded on demand), `scripts/` (automation), `assets/` (static files), and
  `agents/` (skill-scoped subagents).
- All directory and file names are kebab-case.

## SKILL.md frontmatter

```yaml
---
name: my-skill            # required; kebab-case; MUST equal the folder name;
                          # must not start with "claude" or "anthropic"
description: >            # required; <= 1024 chars
  First sentence says what the skill does.
  Use when "trigger phrase one", "trigger phrase two".
  NOT for <case> (use <other-skill>).
author: Emi Higgins    # optional
version: 1.0.0            # optional; semver
argument-hint: "[arg]"    # optional; hint shown for /my-skill
user-invocable: true      # optional; set false to hide from /skills
---
```

The `description` is how Claude decides when to auto-invoke the skill, so make the
trigger phrases concrete and add `NOT for ...` lines pointing at the right
alternative skill.

## Category prefixes

Group skills by a directory-name prefix (also the `name`). Prefixes are a
convention, not folders — `validate-skill.sh` only warns on mismatches.

| Prefix | Category | Example |
|--------|----------|---------|
| `tool-` | Wrappers around an external resource / API | `tool-github` |
| `code-{framework}-` | Framework-specific code patterns | `code-react-forms` |
| `workflow-` | Multi-phase orchestrated workflows | `workflow-release` |
| _(none)_ | Atomic utility skills | `changelog` |

Add your own prefixes as the marketplace grows — document them in this table.

## Agents

- Plugin-wide agents: `plugins/<plugin>/agents/<name>.md`. Skill-scoped agents:
  `plugins/<plugin>/skills/<skill>/agents/<name>.md`.
- Agent files are Markdown with YAML frontmatter (`description`, optional `model`).
  `description` decides when the agent is selected; `model` is `haiku` (light),
  `sonnet` (default/fast), or `opus` (complex reasoning).

## Validation

Run `bash scripts/validate-skill.sh plugins/<plugin>/skills/<name>` before opening a PR.
