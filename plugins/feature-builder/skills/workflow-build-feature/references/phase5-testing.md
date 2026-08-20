# Phase 5: Test & Verify — Full Procedure

> **Read by orchestrator on-demand** when entering Phase 5. Not loaded with SKILL.md.

🧪 TESTING - Verifying acceptance criteria...

**BEFORE delegating:** Update state.json phase to `"testing"`.

## Phase 5.routing: MANDATORY Tester Routing Check

**DO NOT SKIP THIS STEP.** Incorrect routing has occurred in every test run — get it right.

1. **Read state.json** from the session directory right now (re-read it, do NOT rely on earlier memory)
2. **Check the `isUIProject` field** — it is `true` or `false`
3. **Print the routing decision before delegating:**
   ```
   🧪 Tester routing: isUIProject={value} → using {ui-tester|tester}
   ```

**Route based on isUIProject:**
- `isUIProject: true` → **MUST use `some-claude-skills:ui-tester`** (has Playwright MCP, NO Bash)
- `isUIProject: false` → **MUST use `some-claude-skills:tester`** (has Bash for curl/newman, no Playwright)

**WRONG:** Using `some-claude-skills:tester` for a UI project. The tester agent has Bash and will run unit tests (`jest`, `npm test`) instead of Playwright browser verification. This defeats the purpose of UI acceptance testing.
**RIGHT:** Using `some-claude-skills:ui-tester` for a UI project. It has no Bash — it can ONLY verify via Playwright browser automation.

## Phase 5.pre: Start Dev Server (UI Projects Only)

**The ui-tester has no Bash access — it cannot start a dev server.** You (the orchestrator) MUST start it before delegating to ui-tester.

**Skip this step if:** `isUIProject: false`, or `mcpAvailable.playwright: false` (no point starting server without Playwright).

1. **Find the dev server command:** Read the project's CLAUDE.md for a dev server command (look for `dev`, `start`, `serve` in scripts section, or a documented dev URL). If not in CLAUDE.md, read `package.json` and check `scripts` for `dev`, `start`, or `serve`.

2. **Find the dev URL:** Check CLAUDE.md for a documented URL (e.g., `http://localhost:3000`). If not found, default to `http://localhost:3000`. For component harnesses (Storybook, etc.), the URL/port may differ.

3. **Start the server in background:**
```bash
# Example (adapt command from step 1):
nohup npm run dev > /tmp/dev-server-${sessionId}.log 2>&1 &
echo $!
```
Save the PID from output.

4. **Wait for server to be ready (max 60 seconds):**
```bash
for i in $(seq 1 30); do
  curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -qE "^(200|304)" && echo "READY" && break
  sleep 2
done
```

5. **If server fails to start:** Check the log file (`/tmp/dev-server-${sessionId}.log`). Common issues: port in use, missing deps. If it cannot start, note `devServerFailed: true` in state.json — ui-tester will fall back to manual verification.

6. **Pass `devServerUrl` to ui-tester** in the delegation prompt (e.g., `devServerUrl: "http://localhost:3000"`).

## Phase 5.post: Stop Dev Server (After ui-tester returns)

After ui-tester completes, kill the dev server:
```bash
kill <PID> 2>/dev/null || true
```

If you lost the PID, find and kill by port:
```bash
lsof -ti:<PORT> | xargs kill 2>/dev/null || true
```

## Delegation

Include in delegation: session_dir, working_dir, plugin_root, requirements, plan, review, devServerUrl (if started).

**Parse output contract:**
- `VERDICT: PASS` → continue to manual verification
- `VERDICT: FAIL` → route to coder with test-results.md context
- `VERDICT: BLOCKED` → ask user for help
- `VERDICT: PARTIAL` → decide whether to fix or proceed

**Use `scripts/summarize-tests.sh`** for quick counts.

## Phase 5.5: Manual Verification

**Quick mode:** Skip by default. Honor explicit user request.
**Headless mode:** Skip entirely.

👤 MANUAL VERIFICATION — Please test the implementation yourself.

```
1. Looks good — proceed to commit
2. Found issues — describe what's wrong and I'll fix it
3. Skip manual testing — proceed as-is
```

If issues found: delegate to coder with `phase: "FIX_MANUAL_TESTING_ISSUES"`, then re-present options. Track rounds.

Update state.json phase to `"manual-verification"` (checkpoint).
