# some-claude-skills

A **Claude Code plugin marketplace** published from a single repo. It ships two
plugins so consumers can pick their exposure:

| Plugin | What you get | Hooks it installs |
| --- | --- | --- |
| [`skills-core`](plugins/skills-core) | The atomic, framework-free skills below (`brainstorm`, `create-skill`, `day-in-review`, `scaffold-skill-marketplace`, `setup-feature-branch`, `example-tool-skill`). | One skill-recommender hook (surfaces relevant skills based on your prompt). |
| [`feature-builder`](plugins/feature-builder) | The `workflow-build-feature` multi-agent orchestrator + `generate-project-context`, 8 specialized subagents, workflow-enforcement hooks, and stack templates. | ~15 workflow-enforcement hooks (block `cd` in Bash, `git push` guard, artifact-on-SubagentStop, MCP checks, etc.). |

Install one or both.

## Install

### For a project (recommended)

Add to the consuming repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "some-claude-skills": {
      "source": { "source": "github", "repo": "emihiggins/some-claude-skills" }
    }
  },
  "enabledPlugins": {
    "skills-core@some-claude-skills": true,
    "feature-builder@some-claude-skills": true
  }
}
```

Set either plugin to `false` (or omit it) to skip that half.

### For an individual developer

```bash
claude /plugin marketplace add emihiggins/some-claude-skills
claude /plugin install skills-core@some-claude-skills
# Optional — only if you want the multi-agent workflow + its hooks:
claude /plugin install feature-builder@some-claude-skills
```

### Grab a single skill (no plugin install)

Copy just one skill into your personal `~/.claude/skills/`:

```bash
git clone https://github.com/emihiggins/some-claude-skills.git /tmp/scs
# Atomic skill:
cp -R /tmp/scs/plugins/skills-core/skills/<skill-name> ~/.claude/skills/
# Or a workflow skill:
cp -R /tmp/scs/plugins/feature-builder/skills/<skill-name> ~/.claude/skills/
```

Restart Claude Code and the skill will be discovered automatically. Note: the
`workflow-build-feature` skill won't function this way without also copying its
agents/, hooks/, scripts/, and templates/ — use the plugin install for that.

## Available skills

### `skills-core`

| Skill | Description |
| --- | --- |
| [`brainstorm`](plugins/skills-core/skills/brainstorm/SKILL.md) | Structured design-exploration dialogue for turning vague ideas into concrete designs before implementation planning. |
| [`create-skill`](plugins/skills-core/skills/create-skill/SKILL.md) | Unified authoring lifecycle for new skills, workflows, and agents inside a Claude Code plugin — scaffolds files, checks taxonomy, and validates structure. |
| [`day-in-review`](plugins/skills-core/skills/day-in-review/SKILL.md) | Builds an end-of-day HTML work recap from GitHub, Jira, calendar, Confluence, Slack, and deploy sources, plus a cumulative local ledger. |
| [`scaffold-skill-marketplace`](plugins/skills-core/skills/scaffold-skill-marketplace/SKILL.md) | Scaffolds a new git repository structured as a Claude Code plugin marketplace — this repo was bootstrapped with it. |
| [`setup-feature-branch`](plugins/skills-core/skills/setup-feature-branch/SKILL.md) | Creates a properly-named git feature branch, optionally deriving a name from a ticket via any available issue-tracker MCP. |

### `feature-builder`

| Skill | Description |
| --- | --- |
| [`workflow-build-feature`](plugins/feature-builder/skills/workflow-build-feature/SKILL.md) | Multi-agent orchestrator that drives a feature from requirements through plan, implement, review, and test in an iterative loop. |
| [`generate-project-context`](plugins/feature-builder/skills/generate-project-context/SKILL.md) | Generates or sets up a project's `CLAUDE.md` via auto-scan, stack template, or guided creation. Called by the workflow's preflight step. |

## Local development

Point Claude Code at a local checkout without installing:

```bash
claude --plugin-dir /path/to/this/repo
```

Then run `/skills` to see the skills each plugin provides.

## Repository layout

```
.claude-plugin/marketplace.json     Lists the two plugins below
plugins/
  skills-core/
    .claude-plugin/plugin.json      Plugin manifest
    hooks/                          hooks.json + scripts/recommend-skills.sh
    skills/                         One directory per atomic skill
  feature-builder/
    .claude-plugin/plugin.json      Plugin manifest
    agents/                         Subagents used by the workflow
    hooks/                          hooks.json + workflow-enforcement scripts
    scripts/                        session-manager, preflight, run-checks, ...
    templates/                      Stack-specific CLAUDE.md templates
    skills/                         workflow-build-feature + generate-project-context
scripts/                            Marketplace-level tooling (validate-skill, update-plugin-versions)
```

## Contributing

See `CONTRIBUTING.md` for the workflow and `CLAUDE.md` for authoring conventions.
Validate any skill you add with:

```bash
bash scripts/validate-skill.sh plugins/<plugin>/skills/<skill-name>
```

## License

MIT — see [`LICENSE`](LICENSE).
