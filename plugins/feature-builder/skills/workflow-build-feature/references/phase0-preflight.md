# Phase 0: Preflight — Full Procedure

> **Read by orchestrator on-demand** when entering Phase 0. Not loaded with SKILL.md.

### 0.1 Run Preflight Script

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh" "{working-dir}"
```

This returns JSON with: git state, .gitignore status, CLAUDE.md presence, active sessions, project type, MCP config. Use this output to skip manual checks below.

### 0.2 Handle Incomplete Sessions

**Headless mode:** Skip entirely (session-dir is pre-created by lead).

Use `find-active` subcommand:
```bash
session-manager find-active "{working-dir}"
```

**If incomplete sessions found**, present to user:
```
Found incomplete session from earlier run:
- Session: {session-id}
- Branch: {branch-name}
- Last phase: {phase}

1. Resume from where it left off
2. Start fresh (new branch, mark old as abandoned)
3. Start fresh on this branch (mark old as abandoned)
```

**Resume:** Read session files, skip to "Resuming Crashed Sessions" section in SKILL.md.
**Start fresh:** Abandon old session:
```bash
session-manager abandon "{old-session-dir}" "User started new session"
```

### 0.3 Restore Pending Request

Check preflight output for `session.has_pending_request`. If true, read `.workflow-sessions/.pending-request.md`, use as `FEATURE_REQUEST`, delete the file.

### 0.4 Ensure .gitignore

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/gitignore-check.sh" "{working-dir}" --fix
```

Proceed silently regardless of outcome.

### 0.5 Check CLAUDE.md

**Headless mode:** Run the detection script silently (record results in state.json) but skip ALL interactive prompts. If CLAUDE.md doesn't exist, proceed without it.

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/claude-md-check.sh" "{working-dir}"
```

The script now returns monorepo-aware output including `monorepo.is_asset`, `monorepo.asset_claude_md.exists`, and `monorepo.root_claude_md.exists`.

**Case 1: CLAUDE.md exists in working directory** (`exists: true` AND `monorepo.asset_claude_md.exists: true`, OR non-monorepo with `exists: true`) → Proceed.

**Case 2: Monorepo asset, root CLAUDE.md exists but NO asset-level CLAUDE.md** (`monorepo.is_asset: true` AND `monorepo.asset_claude_md.exists: false` AND `monorepo.root_claude_md.exists: true`) → Prompt:
```
Use AskUserQuestion:
  Question: "Found a CLAUDE.md at the monorepo root, but this asset folder doesn't have its own. Each asset can have different structure, build commands, and conventions. How would you like to proceed?"
  Header: "Asset CLAUDE.md"
  Options:
    1. "Generate for this asset (Recommended)" - Scan this folder and create an asset-specific CLAUDE.md
    2. "Create from template" - Use a stack-specific template
    3. "Use root CLAUDE.md only" - Proceed with the monorepo-wide CLAUDE.md
```

**If "Generate":** Invoke generate-project-context in asset mode:
```
Skill(skill: "some-claude-skills:generate-project-context", args: "generate --asset")
```

**If "Create from template":** Invoke generate-project-context in template mode:
```
Skill(skill: "some-claude-skills:generate-project-context", args: "template")
```
Note: Template mode writes to `./CLAUDE.md` in the current (asset) directory. The template content is not monorepo-aware, but the file lands in the right place.

**If "Use root only":** Proceed with root CLAUDE.md. Note in state.json: `"claudeMdSource": "root-only"`.

**Case 3: No CLAUDE.md anywhere** (`exists: false`) → Check if monorepo asset:

**If monorepo asset** (`monorepo.is_asset: true`):
```
Use AskUserQuestion:
  Question: "No CLAUDE.md found (not in this asset folder or the monorepo root). CLAUDE.md tells agents about your tech stack, project structure, testing commands, and conventions. How would you like to set it up?"
  Header: "CLAUDE.md"
  Options:
    1. "Generate for this asset (Recommended)" - Scan this folder and create an asset-specific CLAUDE.md
    2. "Create from template" - Use a stack-specific template
    3. "Continue without" - Proceed with generic guidance (not recommended)
    4. "Cancel workflow" - Stop here so you can set up CLAUDE.md manually
```
- "Generate" → `Skill(skill: "some-claude-skills:generate-project-context", args: "generate --asset")`
- "Create from template" → `Skill(skill: "some-claude-skills:generate-project-context", args: "template")`

**If NOT monorepo asset** (standalone project):
```
Use AskUserQuestion:
  Question: "No CLAUDE.md found. CLAUDE.md tells agents about your tech stack, project structure, testing commands, and conventions. How would you like to set it up?"
  Header: "CLAUDE.md"
  Options:
    1. "Create from template (Recommended)" - Use a stack-specific template with architectural guidance
    2. "Generate CLAUDE.md" - Scans your project and generates a tailored CLAUDE.md automatically
    3. "Continue without" - Proceed with generic guidance (not recommended)
    4. "Cancel workflow" - Stop here so you can set up CLAUDE.md manually
```
- "Create from template" → `Skill(skill: "some-claude-skills:generate-project-context", args: "template")`
- "Generate" → `Skill(skill: "some-claude-skills:generate-project-context", args: "generate")`

**If "Continue without":** Set `"claudeMdExists": false` in state.json.
**If "Cancel":** Exit gracefully.

### 0.6 Get Ticket & Create Branch

**Headless mode:** Skip entirely. Use `--branch` parameter value. The branch is already created and checked out by the team lead. Extract TICKET_ID from the branch name (e.g., `feat/PROJ-123-description` → `PROJ-123`). Verify the branch is checked out: `git rev-parse --abbrev-ref HEAD`.

```
Use AskUserQuestion:
  Question: "What is the ticket number for this feature?"
  Options:
    1. "Jira ticket (e.g., PROJ-123)"
    2. "GitHub issue (e.g., GH-456)"
    3. "No ticket - use feature name"
```

**Ensure main is up to date before branching** (critical — stale main means the coder won't see code from recent PRs):
```bash
git checkout main
git pull origin main
```

Invoke branch setup skill:
```
Skill(skill: "some-claude-skills:setup-feature-branch", args: "{TICKET_ID} {brief-description}")
```

**Continue immediately after branch creation — silent transition.**

### 0.7 Detect Project Type & Profile

Use `detect-project.sh` output from preflight, or run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/detect-project.sh" "{working-dir}"
```

**Profile detection (use Glob):**
- `pom.xml` + `.kt` files → profile: `kotlin-maven`
- More profiles future

Store `PROJECT_TYPE` and `profile` in state.json. When delegating to agents, include:
```
Stack profile: {profile-name} (read {plugin-root}/profiles/{profile-name}.md for standard build commands)
```

### 0.8 Check MCP Availability (CRITICAL GATE)

**Headless mode:** Run Steps 1-2 (ToolSearch detection) silently. Skip Steps 3-5 (no interactive MCP setup prompts — if MCPs are missing, proceed without them). Jump directly to Step 6 (write mcpAvailable to state.json).

**Print visual marker:**
```
🔌 MCP AVAILABILITY CHECK - Detecting configured MCP servers...
```

**CRITICAL:** This check MUST complete and write `mcpAvailable` to state.json BEFORE proceeding to Phase 1. A SubagentStart hook enforces this - requirements-gatherer cannot start without it.

**SCOPE RESTRICTION:** During Phase 0.8, you may ONLY:
- ✅ Call ToolSearch to detect MCP servers
- ✅ Prompt user with AskUserQuestion
- ✅ Write/Edit config files
- ✅ Run npm install commands
- ✅ Write to state.json

**You may NOT:**
- ❌ Search codebases (Grep, Glob)
- ❌ Read project files (except package.json for UI detection)
- ❌ Search node_modules
- ❌ Explore component APIs
- ❌ Analyze code structure

Those actions belong in Phase 1 (Requirements) or Phase 2 (Planning), NOT Phase 0.8.

**Step 1: Early UI Project Detection**

Analyze the FEATURE_REQUEST description for UI indicators:
- Figma URLs
- design system component names (Button, Card, etc.)
- UI keywords: page, form, modal, screen, layout, component, frontend, React
- Package.json with `design-system` dependencies

If 2+ indicators present → tentatively classify as UI project for MCP checking purposes. Store preliminary flag.

**Step 2: Check Available MCP Servers (MANDATORY - DO NOT SKIP)**

**CRITICAL:** You MUST call ToolSearch for each MCP server BEFORE any other exploration. Do NOT search codebases, do NOT read files, do NOT analyze project structure until this step completes.

Call ToolSearch exactly as shown below (one call per server):

1. **Check Jira/Confluence:**
   ```
   ToolSearch(query: "+atlassian jira", max_results: 1)
   ```
   Record: `jira: true` if tools found, `jira: false` if not

2. **Check Figma:**
   ```
   ToolSearch(query: "+figma", max_results: 1)
   ```
   Record: `figma: true` if tools found, `figma: false` if not

3. **Check design system:**
   ```
   ToolSearch(query: "+design-system", max_results: 1)
   ```
   Record: `designSystem: true` if tools found, `designSystem: false` if not

4. **Check Playwright:**
   ```
   ToolSearch(query: "+playwright", max_results: 1)
   ```
   Record: `playwright: true` if tools found, `playwright: false` if not

**DO NOT PROCEED** to Step 3 until all four ToolSearch calls have completed and results are recorded.

**Step 3: Analyze Missing MCPs and Batch Setup**

**Determine which MCPs are needed:**

Analyze FEATURE_REQUEST and Step 1 results:
- **Jira needed?** Check if request mentions "JIRA-", "ticket", or user said they have a Jira ticket
- **Figma needed?** Check if request contains `figma.com` URLs
- **design system needed?** If UI project (from Step 1) → REQUIRED
- **Playwright needed?** If UI project → REQUIRED (ui-tester agent needs it for browser automation)

**Build missing MCP lists (MANDATORY - DO NOT SKIP):**

**YOU MUST COMPLETE THIS STEP BEFORE PROMPTING USER:**

```
REQUIRED_MISSING = []  # Blocking for this workflow
OPTIONAL_MISSING = []  # Nice to have

if UI_PROJECT and not ds_available:
    REQUIRED_MISSING.append("designSystem")

if UI_PROJECT and not playwright_available:
    REQUIRED_MISSING.append("playwright")  # Required for UI — ui-tester agent needs it

if jira_needed and not jira_available:
    REQUIRED_MISSING.append("jira")

if figma_needed and not figma_available:
    REQUIRED_MISSING.append("figma")
```

**CHECKPOINT - Before proceeding, write your analysis:**
```
Analysis:
- UI_PROJECT: {true/false}
- ds_available: {true/false}
- playwright_available: {true/false}
- jira_needed: {true/false}
- jira_available: {true/false}
- figma_needed: {true/false}
- figma_available: {true/false}

Result:
REQUIRED_MISSING = [{list actual servers or "none"}]
OPTIONAL_MISSING = [{list actual servers or "none"}]
```

**Only after writing this analysis, proceed to prompt construction.**

**If no missing MCPs:** Skip to Step 6 (write state.json).

**If missing MCPs found:** Present ONE batched prompt with all missing MCPs.

**CRITICAL: You MUST build a custom prompt listing ALL missing MCPs.**

Example of what the prompt should look like (UI project missing both design system and Playwright):

```
REQUIRED_MISSING = ["designSystem", "playwright"]
OPTIONAL_MISSING = []

Then the prompt becomes:

Use AskUserQuestion:
  Question: "This workflow needs MCP servers that aren't configured:

**Required** (workflow will be degraded without these):
- design system - Design system component lookup
- Playwright - Browser automation for UI testing (ui-tester agent needs this)

Which would you like to set up?"
  Header: "⚠️ Missing MCP Servers"
  Options:
    1. "Set up all required (design system + Playwright) - Recommended" - Configure everything now, one restart
    2. "Choose which to set up" - Custom selection
    3. "Continue without MCP" - Use fallbacks (slower, less accurate)
    4. "Cancel workflow" - Stop here to configure manually
```

**MANDATORY STEPS TO BUILD THIS PROMPT:**

1. **List REQUIRED_MISSING in the question text** under "**Required**" section
2. **List OPTIONAL_MISSING in the question text** under "**Optional**" section (if any)
3. **Include server names in option 1** - "Set up all required (design system + Playwright)"
4. **If both REQUIRED and OPTIONAL exist**, add option: "Set up required only ({list})" before "Choose"
5. **If only REQUIRED_MISSING exists (no optional)**, simplify:
   - Option 1: "Set up all required MCPs (design system, Jira)"
   - Option 2: "Choose which to set up"
   - Option 3: "Continue without MCP"
   - Option 4: "Cancel workflow"

**DO NOT use generic text like "Set up all missing MCPs". ALWAYS list the actual server names.**

**If user chooses option 1 (Set up all required):**
- MCPs to configure = REQUIRED_MISSING

**If user chooses option 2 (Choose which):**
```
Use AskUserQuestion:
  Question: "Select which MCP servers to configure:"
  Header: "MCP Selection"
  Options:
    (one option per missing MCP with checkbox-style selection)
```
- MCPs to configure = user's selections

**If user chooses option 3 (Continue without):**
- Print warnings for each REQUIRED_MISSING
- Skip to Step 6

**If user chooses option 4 (Cancel):**
- Exit gracefully, do NOT save pending request

**For each MCP in "MCPs to configure", run setup:**

**Setup Step 1: Ask where to configure (once for all MCPs)**
```
Use AskUserQuestion:
  Question: "Where should I configure the MCP servers?"
  Options:
    1. "User config (~/.claude/config.json)" - Available to all Claude sessions
    2. "Project config (.mcp.json in repo root)" - Only for this project
```

**Setup Step 2: Write config for all selected MCPs**

**Target file:**
- User config: `~/.claude/config.json` (or `claude_desktop_config.json` on macOS)
- Project config: `{monorepo-root}/.mcp.json`

**For each MCP in "MCPs to configure", add the appropriate config block:**

**Design System MCP** (if selected):
```json
"designSystem": {
  "command": "npx",
  "args": ["-y", "mcp-remote", "https://YOUR_DESIGN_SYSTEM_MCP_URL"],
  "env": {"NODE_TLS_REJECT_UNAUTHORIZED": "0"}
}
```

**Playwright MCP** (if selected):

**Preferred: Install the official Playwright plugin from the Claude marketplace:**
```
/plugin install playwright@claude-plugins-official
```
This is the recommended approach — no .mcp.json config needed.

**Alternative: Manual .mcp.json config:**
```json
"playwright": {
  "command": "npx",
  "args": ["-y", "@playwright/mcp@latest"]
}
```

**Jira MCP** (if selected):
```json
"atlassian-jira": {
  "type": "sse",
  "url": "https://mcp.atlassian.com/v1/sse"
}
```

**Figma MCP** (if selected):
```json
"figma": {
  "type": "http",
  "url": "https://mcp.figma.com/mcp"
}
```

**Combine all into one mcpServers object:**
```
Use Write (if creating new) or Edit (if file exists) to add/update mcpServers section with all selected MCPs.

Example with design system + Playwright:
{
  "mcpServers": {
    "designSystem": { ... },
    "playwright": { ... }
  }
}
```

**Note:** `npx -y` auto-installs packages on first use (no manual npm install needed).

**Setup Step 3: Save pending request**
```
Use Write: {working-dir}/.workflow-sessions/.pending-request.md
Content: {FEATURE_REQUEST}
```

**Setup Step 4: Exit gracefully with restart instructions**
```
✅ MCP Configuration Complete

Configured servers: {list of MCPs set up}

Please restart Claude Code completely (quit and relaunch).

When you restart, run:
  /some-claude-skills:workflow-build-feature

The workflow will automatically:
  - Detect your pending request
  - Resume with MCP servers available
  - Begin implementing your feature
```

**Step 6: Write mcpAvailable to state.json**

**MANDATORY:** Write the `mcpAvailable` object to state.json via Write tool:

```json
"mcpAvailable": {
  "jira": true/false,
  "figma": true/false,
  "designSystem": true/false,
  "playwright": true/false
}
```

Also record `testingCapability` and preliminary `isUIProject` flag.

**Testing capability warning:** If UI project without Playwright or API without start command, print informational warning (don't block).

**COMPLETION CHECK:**
- ✅ ToolSearch called for all 4 MCP servers (jira, figma, designSystem, playwright)
- ✅ Missing MCPs analyzed and categorized (required vs optional)
- ✅ If missing required MCPs: user prompted and responded (or workflow exited)
- ✅ mcpAvailable object written to state.json
- ✅ No codebase exploration happened during this phase

**After Phase 0.8 completes:**
- Print: `✅ MCP availability check complete`
- Silent transition to Phase 0.9 (Java version check) or Phase 0.10 (Session creation)
- The hook will block requirements-gatherer if mcpAvailable is missing from state.json

### 0.9 Java Version Check (JVM projects only)

**Headless mode:** Skip entirely.

Only for projects with `pom.xml` or `build.gradle*`. Check CLAUDE.md for required version, compare with `java -version`. If mismatch, ask user.

### 0.10 Create Session

**Headless mode:** The session directory already exists at `--session-dir`. Do NOT call `session-manager.sh init`. Instead:
1. Verify `--session-dir` exists and contains `requirements.md`
2. Set the active session pointer: write `--session-dir` path to `{working-dir}/.workflow-sessions/.active-session`
3. Create or update `state.json` in the session directory with collected metadata (see below)
4. Read `requirements.md` from session-dir to extract FEATURE_REQUEST text

**Normal mode:**
```bash
session-manager init "{working-dir}" "session-{YYYYMMDD-HHMMSS}" "{TICKET_ID}" "{BRANCH_NAME}"
```

Then update state.json (via Write tool) with: `projectType`, `mcpAvailable`, `testingCapability`, `claudeMdExists`, `mode`, `profile`, `featureRequest` (the full FEATURE_REQUEST text), and any other collected metadata. The `featureRequest` field is CRITICAL for session resume — without it, a resumed session cannot re-run failed agents.

Output initialization summary:
```
✅ Session initialized:
- Session ID: {session-id}
- Branch: {branch-name}
- Ticket: {TICKET_ID}
- Project Type: {PROJECT_TYPE}
```
