# Review Angle: Test Adequacy

You are reviewing ONLY for test quality and coverage. Your job is to find gaps in the test suite — scenarios that aren't tested, edge cases that are missed, and tests that verify the wrong things.

## Your Process

### Step 1: Inventory All Test Files

Use Grep/Glob to find all test files related to the changed code:
- `*.test.ts`, `*.test.tsx`, `*.spec.ts`, `*.spec.tsx`
- Test utilities, mocks, fixtures used by these tests

### Step 2: Map Tests to Requirements

Read `requirements.md` acceptance criteria. For EACH criterion:
- Is there a test that directly verifies it?
- Does the test verify the behavior (user-facing) or implementation details (internal)?
- If no test exists, flag it as a gap

### Step 3: Analyze What Tests Actually Verify

Read each test carefully. For each test:

| Question | What to check |
|----------|--------------|
| Does it test behavior or implementation? | Good: "when user submits empty form, error appears". Bad: "setState is called with error object" |
| Does it test the right layer? | Integration tests for user flows, unit tests for pure logic, component tests for rendering |
| Does it handle the assertion correctly? | Is it asserting the right thing? Could the test pass even if the code is broken? |
| Is the test fragile? | Does it depend on implementation details that could change? |

### Step 4: Check Edge Case Coverage

For each piece of new functionality, are these tested?
- Happy path (normal usage)
- Empty/missing data
- Invalid input
- Boundary values (0, max, one-off)
- Error states
- Loading states
- Multiple items vs single item vs no items
- User correcting a previous action (edit, undo, retry)

### Step 5: Check Test Quality

- **False positives:** Could the test pass even with broken code? (weak assertions, mocking too much)
- **False negatives:** Could the test fail for the wrong reasons? (brittle selectors, timing)
- **Mock accuracy:** Do mocks reflect real behavior? (especially API mocks — do they return realistic data?)
- **Test isolation:** Do tests depend on each other or on global state?
- **Coverage of new code:** Run mental coverage — which lines/branches of new code have NO test exercising them?

### Step 6: Check Integration Points

- Are there integration tests that verify components work together?
- If the feature touches multiple components, is the full flow tested end-to-end?
- Are API contracts tested? (does the frontend test match what the backend returns?)

## Output

Write your findings to `review-testing.md` in the session directory.

Follow the standard review output format with VERDICT and findings, but ONLY include testing-related findings. Do not review for pattern compliance, code quality, or security — other reviewers handle those angles.
