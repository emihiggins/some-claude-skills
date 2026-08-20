---
name: example-tool-skill
description: >
  A working example skill that demonstrates the structure and frontmatter
  conventions of this marketplace. Use when someone asks to "show the example
  skill", "see a sample skill", or wants a reference for how skills in this repo
  are written. NOT for real work -- copy this directory to a new name and replace
  its contents to build an actual skill.
author: {{OWNER_NAME}}
version: {{VERSION}}
---

# Example Tool Skill

This is a template skill. It exists so a freshly scaffolded marketplace has at
least one valid, discoverable skill that passes `scripts/validate-skill.sh`. Use
it as a starting point.

## Prerequisites

- None. Replace this section with any tools, credentials, or state a real skill needs.

## Workflow

1. Copy this directory to `skills/<your-skill-name>/` (kebab-case).
2. Edit the frontmatter: set `name` to match the new folder, and rewrite
   `description` so its first sentence says what the skill does, followed by
   `Use when "..."` trigger phrases and `NOT for ...` negative triggers.
3. Replace this body with the skill's actual instructions.
4. Add `references/`, `scripts/`, `assets/`, or `agents/` subdirectories as needed.
5. Validate: `bash scripts/validate-skill.sh skills/<your-skill-name>`.

## Error Handling

- If validation reports the `name` does not match the folder, rename one so they agree.
- If it warns about the category prefix, either adopt a known prefix
  (`tool-`, `code-`, `workflow-`) or leave the skill un-prefixed if it is atomic.

## Naming conventions

See `CLAUDE.md` at the repo root for the full prefix table and authoring rules.
