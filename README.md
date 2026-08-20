# some-claude-skills

Claude Code skills and agents for some-claude-skills

This repository is a **Claude Code plugin marketplace**. It publishes one plugin,
`some-claude-skills`, containing skills (and optionally agents and hooks) that anyone
can install into their own Claude Code sessions.

## Install

### For a project (recommended)

Add this to the consuming repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "some-claude-skills": {
      "source": { "source": "github", "repo": "emihiggins/some-claude-skills" }
    }
  },
  "enabledPlugins": {
    "some-claude-skills@some-claude-skills": true
  }
}
```

### For an individual developer

```bash
claude /plugin marketplace add emihiggins/some-claude-skills
claude /plugin install some-claude-skills@some-claude-skills
```

### Grab a single skill (no plugin install)

If you'd rather copy just one skill into your personal `~/.claude/skills/`:

```bash
git clone https://github.com/emihiggins/some-claude-skills.git /tmp/scs
cp -R /tmp/scs/skills/<skill-name> ~/.claude/skills/
```

Restart Claude Code and the skill will be discovered automatically.

## Available skills

| Skill | Description |
| --- | --- |
| [`day-in-review`](skills/day-in-review/SKILL.md) | Builds an end-of-day HTML work recap from GitHub, Jira, calendar, Confluence, Slack, and deploy sources, plus a cumulative local ledger. |
| [`scaffold-skill-marketplace`](skills/scaffold-skill-marketplace/SKILL.md) | Scaffolds a new git repository structured as a Claude Code plugin marketplace — this repo was bootstrapped with it. |

## Local development

Point Claude Code at a local checkout without installing:

```bash
claude --plugin-dir /path/to/this/repo
```

A handy alias:

```bash
alias claude-dev='claude --plugin-dir /path/to/this/repo'
```

Then run `/skills` to see the skills this marketplace provides.

## Repository layout

```
.claude-plugin/     marketplace.json + plugin.json (manifests)
skills/             one directory per skill (skills/<name>/SKILL.md)
agents/             repo-wide agents (optional)
hooks/              lifecycle hooks (hooks.json + scripts/)
scripts/            validation + release tooling
```

## Contributing

See `CONTRIBUTING.md` for the workflow and `CLAUDE.md` for authoring conventions.
Validate any skill you add with `bash scripts/validate-skill.sh skills/<name>`.
