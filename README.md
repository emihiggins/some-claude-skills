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
      "source": { "source": "github", "repo": "<owner>/<repo>" }
    }
  },
  "enabledPlugins": {
    "some-claude-skills@some-claude-skills": true
  }
}
```

Replace `<owner>/<repo>` with this repository's GitHub path.

### For an individual developer

```bash
claude /plugin marketplace add <owner>/<repo>
claude /plugin install some-claude-skills@some-claude-skills
```

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
