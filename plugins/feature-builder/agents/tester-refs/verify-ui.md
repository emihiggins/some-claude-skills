# UI Verification Reference

Verify that UI implementation meets acceptance criteria through browser automation or structured manual testing.

## Inputs

- Acceptance criteria (from requirements.md)
- App URL (from CLAUDE.md or state.json)
- Playwright MCP availability

## Step 1: Check Playwright MCP Availability

**Playwright MCP is highly recommended for agentic workflows.** Proceeding without it is **highly discouraged** - it allows agents to interactively test components without writing test files.

**Detection:** Check if `mcp__playwright__*` tools are in your tool list by attempting to call `mcp__playwright__browser_navigate`. If the tool exists, Playwright MCP is available. Do NOT use ToolSearch (you don't have access to it).

**If Playwright tools are available** → use automated verification (Step 2a)

**If Playwright NOT available** (tool call fails or not in tool list) → prompt user:

```
Use AskUserQuestion:
  Question: "Playwright MCP is not configured. It is highly recommended for UI verification. How would you like to proceed?"
  Options:
    1. "Exit and configure Playwright (Recommended)" - I'll set up MCP first
    2. "Proceed with manual verification (Highly Discouraged)" - I'll verify manually in browser
    3. "Skip UI verification" - Proceed without verification
```

- **Option 1:** Tell user to add Playwright to `.mcp.json`:
  ```json
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
  ```
  Then restart Claude and re-run workflow.

- **Option 2:** Proceed with manual verification (Step 2b) but note in results that automated verification was skipped.

- **Option 3:** Skip verification entirely, note as "NOT VERIFIED" in results.

## Step 2a: Automated Verification (Playwright Available)

### Playwright MCP Tools Reference

**Navigation:**
| Tool | Description | Parameters |
|------|-------------|------------|
| `mcp__playwright__browser_navigate` | Navigate to URL | `url` (required) |
| `mcp__playwright__browser_navigate_back` | Go back | none |
| `mcp__playwright__browser_tabs` | Manage tabs | `action` ("list", "new", "close", "select"), `index` |

**Page Inspection:**
| Tool | Description | Parameters |
|------|-------------|------------|
| `mcp__playwright__browser_snapshot` | **Get page structure with element refs** - USE THIS for interactions | `filename` (optional) |
| `mcp__playwright__browser_take_screenshot` | Take visual screenshot | `type` ("png"/"jpeg"), `fullPage`, `element`, `ref`, `filename` |
| `mcp__playwright__browser_console_messages` | Get console messages | `level` ("error", "warning", "info", "debug") |

**Interactions:**
| Tool | Description | Parameters |
|------|-------------|------------|
| `mcp__playwright__browser_click` | Click element | `ref` (required), `element`, `button`, `doubleClick`, `modifiers` |
| `mcp__playwright__browser_type` | Type text | `ref` (required), `text` (required), `slowly`, `submit` |
| `mcp__playwright__browser_hover` | Hover over element | `ref` (required), `element` |
| `mcp__playwright__browser_select_option` | Select dropdown | `ref` (required), `values` (required array) |
| `mcp__playwright__browser_press_key` | Press key | `key` (required, e.g., "Enter", "Tab", "Escape") |
| `mcp__playwright__browser_fill_form` | Fill multiple fields | `fields` array |
| `mcp__playwright__browser_handle_dialog` | Handle alert/confirm | `accept` (required boolean), `promptText` |

**Waiting:**
| Tool | Description | Parameters |
|------|-------------|------------|
| `mcp__playwright__browser_wait_for` | Wait for condition | `text`, `textGone`, `time` (seconds) |

### Key Concept: Element Refs

**Always call `browser_snapshot` first** to get element `ref` values. The snapshot returns an accessibility tree with refs like `ref="button[0]"` or `ref="textbox[2]"`. Use these exact refs in interaction tools.

- `browser_snapshot` → Returns structured data with refs, **USE THIS for interactions**
- `browser_take_screenshot` → Returns visual image, use for verification only

### Screenshot Storage (IMPORTANT)

**Never save screenshots to the project root.** Use a temp directory or the session directory:
- Preferred: `/tmp/playwright-screenshots/` or `{session-dir}/screenshots/`
- Clean up screenshots after verification is complete
- Do not leave PNG/JPEG files in the repo

### Troubleshooting: Screenshot Timeouts

If `browser_take_screenshot` times out repeatedly (even on simple pages):
- The browser instance is likely in a bad state (stale session, GPU context lost)
- **Do not keep retrying on the same session** — it wastes time and tokens
- Close the browser and relaunch a fresh Playwright instance
- Then retry the screenshot on the new session

### Verification Workflow

For each acceptance criterion:

```
1. browser_navigate      → Go to URL
2. browser_snapshot      → Get page structure with element refs
3. browser_click/type    → Interact using refs from snapshot
4. browser_snapshot      → Verify result after interaction
5. browser_take_screenshot → Visual evidence (optional)
```

**Example:**
```
Criterion: "User can submit the hold form"

1. mcp__playwright__browser_navigate
   url: "http://localhost:8002/?component=NewHoldForm&scenario=success"

2. mcp__playwright__browser_snapshot
   # Returns refs like textbox[0], button[Create]

3. mcp__playwright__browser_type
   ref: "textbox[0]"
   text: "Test hold reason"

4. mcp__playwright__browser_click
   ref: "button[Create]"

5. mcp__playwright__browser_snapshot
   # Verify success toast/message appears

6. mcp__playwright__browser_take_screenshot
   type: "png"
   filename: "hold-form-success.png"

Result: PASS with screenshot evidence
```

### Troubleshooting

- **Can't find element ref?** → Call `browser_snapshot` again - page may have changed
- **Dialog blocking?** → Use `browser_handle_dialog` with `accept: true`
- **Need to wait?** → Use `browser_wait_for` with `text` or `time`

## Step 2b: Manual Verification (Playwright Not Available)

For each acceptance criterion, prompt user with specific steps:

```
Use AskUserQuestion:
  Question: "Please verify: [Criterion description]"

  Steps to verify:
  1. Navigate to [specific URL]
  2. [Specific action to take]
  3. [What to observe]

  Options:
    1. "Pass" - Criterion met as expected
    2. "Fail" - Criterion not met (will ask for details)
    3. "Partial" - Partially working (will ask for details)
    4. "Cannot test" - Blocked by something
```

If user selects Fail/Partial, ask follow-up:
```
Use AskUserQuestion:
  Question: "What did you observe?"
  Options:
    1. "Expected X but saw Y" - Describe the difference
    2. "Error occurred" - Describe the error
    3. "Feature missing" - Something not implemented
    4. "Other" - Free text description
```

## Step 3: Compile Results

Return structured verification report:

```markdown
## Verification Results

### Passed
- [Criterion 1]: Verified via Playwright/user confirmation
- [Criterion 2]: Screenshot evidence attached

### Failed
- [Criterion 3]: Expected success message, saw error toast
  - Evidence: [screenshot or user description]
  - Recommendation: Check error handling in submit handler

### Not Tested
- [Criterion 4]: Blocked - API endpoint not available
```

## Output

- Verification report (pass/fail/blocked per criterion)
- Evidence (screenshots if Playwright, user confirmations if manual)
- Recommendations for failures
- Clear indication of what was automated vs manual
