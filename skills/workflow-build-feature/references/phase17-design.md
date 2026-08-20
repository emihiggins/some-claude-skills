# Phase 1.7: Design Creation — Full Procedure

> **Read by orchestrator on-demand** when entering Phase 1.7. Not loaded with SKILL.md.

## When to Skip

Skip this phase if ANY of these are true:
- `isUIProject` is false (not a UI project — see refinement below)
- `requirements.md` contains Figma URLs (mockup already exists)
- Figma MCP is unavailable (`mcpAvailable.figma: false`)
- Design System MCP is unavailable (`mcpAvailable.designSystem: false`)
- Mode is `quick` or `headless`

## isUIProject Refinement (Post-Requirements)

Phase 0.8 did a preliminary UI detection based on the feature request text. Now that `requirements.md` exists, refine the classification:
- Read `requirements.md` for: Figma URLs, design system component names, UI keywords (page, form, modal, component, frontend, React)
- Check for design system component research section (requirements-gatherer writes this for UI projects)
- If confirmed UI → proceed with designer check below
- If NOT UI → set `isUIProject: false` in state.json, skip this phase

## Detecting "No Figma Mockup"

Read `requirements.md` and check for:
- `figma.com` URLs → mockup exists, skip designer
- Figma design context already captured by requirements-gatherer → skip designer
- No Figma references at all → no mockup, invoke designer

## Invoking the Designer

🎨 DESIGNING - Creating visual design for UI feature...

**BEFORE delegating:** Update state.json phase to `"design-creation"`.

Delegate to `some-claude-skills:designer` with:
- `requirements_path: "{session-dir}/requirements.md"`
- `session_dir`, `working_dir`
- `context.mcpAvailable` (from state.json)

## Parse Output Contract

- `VERDICT: DESIGN_CREATED` →

  **BEFORE presenting to user:** Update state.json phase to `"design-review"` (checkpoint — stopping allowed).

  🎨 DESIGN REVIEW — Presenting generated design for approval...

  ```
  Use AskUserQuestion:
    Question: "The designer created a visual design for this feature.

  Figma: {FIGMA_URL}
  Components: {COMPONENTS_USED} design system components selected
  Summary: {SUMMARY}

  Full details in: {session-dir}/design-brief.md

  How would you like to proceed?"
    Header: "🎨 Design Review"
    Options:
      1. "Approve design" - Use this design as the basis for planning
      2. "Open in Figma and review" - I'll check the design first
      3. "Request changes" - Describe what to adjust
      4. "Skip design" - Proceed to planning without a visual design
  ```
  - **Approve / Open and review (then approve):** Continue to Phase 2 with `design-brief.md` as planner input
  - **Request changes:** Re-invoke designer with change request appended to requirements. Max 2 iterations.
  - **Skip:** Continue to Phase 2 without design context.

- `VERDICT: NEEDS_INPUT` → Read `{session-dir}/design-brief.md` "Open Questions" section. Present questions to user via AskUserQuestion (update phase to `"design-review"` first). Re-invoke designer with answers.
- `VERDICT: BLOCKED` → Log warning, write `"designerSkipped": true` to state.json, skip to Phase 2 without design context.

**After design approved or skipped:** Silent transition to Phase 2.
