---
name: setup-feature-branch
description: "Create and validate a properly-named feature branch. Optionally derives a name suggestion from a ticket (Jira/Linear/GitHub) via any available MCP, falling back to asking the user. Use when the user asks to 'start a branch for PROJ-123', 'create a feature branch', or 'set up a branch for this ticket'. NOT for switching to an existing branch, NOT for opening PRs, and NOT for renaming branches after work has started."
argument-hint: "<ticket-id> [description]"
user-invocable: false
allowed-tools: Bash, Read, Glob, AskUserQuestion, ToolSearch
---

# Setup Feature Branch

> **Skill root:** `${CLAUDE_SKILL_DIR}` — reference supporting scripts/files relative to this path.

Create a git branch with the correct naming format for feature development.

## Input

- **ticket-id**: The ticket or issue ID (e.g., `PROJ-123`, `GH-123`)
- **description** (optional): Brief description for branch name (2-4 words)

## Branch Naming Rules

| Format | Example | When to use |
|--------|---------|-------------|
| `{TICKET_ID}/brief_description` | `PROJ-123/hold_form_errors` | Has ticket |
| `feature/brief_description` | `feature/add-error-handling` | No ticket |

**NEVER use:**
- `workflow/` prefix
- `session-` in branch name
- Main/master as the working branch

## Steps

**IMPORTANT: Do NOT use `cd` in any commands.** Git commands work from any subdirectory within a repo. Run all commands directly without changing directory — `cd` to the repo root triggers unnecessary permission prompts.

### 1. Parse Input

Extract ticket ID from the argument:
- `PROJ-123` → ticket ID
- `GH-123` → GitHub issue
- `feature` or empty → no ticket, will use `feature/` prefix

If description not provided, **fetch fresh context** and ask user.

**⚠️ CRITICAL: Always use FRESH data, never old session/branch data.**

**How to get suggestions:**
1. If a ticket ID is provided and an issue-tracker MCP is available (Jira, Linear, GitHub Issues, etc.), fetch the ticket to get its actual title.
2. Use ToolSearch to load whichever tracker MCP is present (e.g. `+atlassian jira`, `+linear`, `+github issues`).
3. Fetch the ticket via that MCP's `getIssue`-equivalent tool.
4. Extract the title and derive 2-3 branch-name suggestions from it.

**Example:**
```
Ticket PROJ-456 title: "Open Create Order full-screen dialog and render form"

Suggestions:
1. create-order-dialog
2. order-form-fullscreen
3. create-order-form
```

**If MCP not available or fetch fails:**
Ask user directly: "What feature does {TICKET_ID} implement? (2-4 words for branch name)"

**NEVER use:**
- Old branch names from abandoned sessions
- Cached data from previous runs
- Guesses based on ticket ID alone

### 2. Check Current State

```bash
# Get current branch
git branch --show-current

# Check for uncommitted changes
git status --porcelain
```

**If uncommitted changes exist:**
```
⚠️ Working directory has uncommitted changes.
Please commit or stash before creating a feature branch.
```
Stop and wait for user to resolve.

### 3. Create Branch

**If already on a correctly-named branch** (matches `{TICKET_ID}/*`):
```
You're already on branch: {branch}
Use this branch? (yes/no)
```

**If on main/master or wrong branch:**
```bash
# Fetch latest
git fetch origin main 2>/dev/null || git fetch origin master

# Checkout main
git checkout main 2>/dev/null || git checkout master

# Pull latest
git pull

# Create new branch
git checkout -b {TICKET_ID}/{description}
```

### 4. Validate (CRITICAL)

After branch creation, verify format:

```bash
BRANCH=$(git branch --show-current)
```

**Validation checks:**
- ✅ Starts with ticket ID or `feature/`
- ✅ Has description after the `/`
- ❌ Does NOT contain `workflow`
- ❌ Does NOT contain `session`
- ❌ Is NOT `main` or `master`

**If validation fails:**
```
⛔ BRANCH VALIDATION FAILED

Created: {actual-branch}
Expected format: {TICKET_ID}/brief_description

Please fix manually or re-run this command.
```

### 5. Output

On success:
```
✅ Feature branch ready:
- Branch: {branch-name}
- Ticket: {ticket-id}
- Base: main
```

**Do not prompt the user or wait. Return immediately so the orchestrator can continue.**

## Examples

**With ticket:**
```
/setup-feature-branch PROJ-123 hold-form-errors

✅ Feature branch ready:
- Branch: PROJ-123/hold-form-errors
- Ticket: PROJ-123
- Base: main
```

**Without ticket:**
```
/setup-feature-branch feature add-dark-mode

✅ Feature branch ready:
- Branch: feature/add-dark-mode
- Ticket: (none)
- Base: main
```
