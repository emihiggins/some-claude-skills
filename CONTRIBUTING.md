# Contributing

Thanks for contributing to **some-claude-skills**! This repo is a Claude Code
plugin marketplace — see `CLAUDE.md` for authoring conventions.

## Workflow

1. Branch from `main`. Suggested names: `skill/<skill-name>` for skill work, or a
   short kebab-case summary for other changes.
2. Add or edit a skill under `skills/<name>/SKILL.md` (and `references/`,
   `scripts/`, `assets/`, `agents/` as needed). No manifest edit is required —
   skills are auto-discovered (`strict: false`).
3. Validate: `bash scripts/validate-skill.sh skills/<name>`.
4. Test locally: `claude --plugin-dir .` then `/skills` to confirm discovery.
5. Open a PR using the template.

## Single-concern PRs

Keep each PR to **one logical objective** (one skill, one fix, one doc change).
The `PR Scope Check` workflow posts a warning if a PR touches many concerns at
once. Smaller PRs review faster and produce a cleaner changelog.

## Conventional Commits

Commit messages drive automated releases (see `.releaserc.json`). Use:

```
<type>(<area>): <summary>
```

Types that trigger a release: `feat` (minor), `fix` / `perf` (patch).
`BREAKING CHANGE:` in the body triggers a major. `docs`, `chore`, `refactor`,
`test`, `ci`, `build`, `style` do not release.

## Releases

On merge to `main`, semantic-release computes the next version, updates
`CHANGELOG.md`, bumps the version in `.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json` (via `scripts/update-plugin-versions.sh`), and
publishes a GitHub release. Consumers pick up changes on their next session.
