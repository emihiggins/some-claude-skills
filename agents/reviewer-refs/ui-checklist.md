# UI Review Checklist

Supplement standard code review with UI-specific checks for accessibility, user experience, and design system compliance.

## Inputs

- Files changed (from review context)
- Design system name (from CLAUDE.md, e.g., "MaterialUI", "none")
- Accessibility requirements (from CLAUDE.md or default WCAG AA)

## Step 1: Accessibility (a11y) Review

**Check each UI component for:**

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Keyboard accessible | Interactive elements use `<button>`, `<a>`, or have `tabIndex` | CRITICAL |
| ARIA labels | Non-semantic elements have `aria-label` or `aria-labelledby` | CRITICAL |
| Form labels | All inputs have associated `<label>` or `aria-label` | CRITICAL |
| Focus visible | `:focus` styles not removed without replacement | HIGH |
| Color contrast | Text meets WCAG AA (4.5:1 normal, 3:1 large) | HIGH |
| Alt text | Images have meaningful `alt` (or `alt=""` if decorative) | HIGH |
| Error announcements | Form errors use `aria-live` or `role="alert"` | MEDIUM |
| Heading hierarchy | Headings follow logical order (h1 → h2 → h3) | MEDIUM |

**Search patterns:**
```
# Missing button semantics
Grep: onClick.*div|onClick.*span (without role="button")

# Missing form labels
Grep: <input(?!.*aria-label)(?!.*id=.*<label)

# Removed focus styles
Grep: :focus.*outline.*none|:focus.*outline.*0
```

## Step 2: Design System Compliance

**If design system specified in CLAUDE.md:**

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Using DS components | Imports from design system package, not custom | HIGH |
| No custom CSS | No `.css`/`.scss` files added (except documented exceptions) | HIGH |
| DS tokens for values | Colors/spacing from tokens, not hardcoded | MEDIUM |
| DS icons | Icons from DS icon set, not custom SVGs | LOW |

**Search patterns:**
```
# Custom CSS files
Glob: **/*.css, **/*.scss, **/*.less (in changed files)

# Hardcoded colors
Grep: #[0-9a-fA-F]{3,6}|rgb\(|rgba\(

# Hardcoded spacing
Grep: margin.*\d+px|padding.*\d+px

# Non-DS imports
Grep: import.*from ['"]\..*\.css
```

**If no design system:**
- Note: "No design system specified - skipping DS compliance checks"

## Step 3: UX Patterns Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Loading states | Async operations show loading indicator | HIGH |
| Error states | Errors displayed with actionable messages | HIGH |
| Empty states | Lists/tables handle empty data gracefully | MEDIUM |
| Confirmation dialogs | Destructive actions require confirmation | MEDIUM |
| Form validation | Inline validation with clear error messages | MEDIUM |
| Responsive behavior | If required, components adapt to viewport | LOW |

**Search patterns:**
```
# Missing loading states
Grep: isLoading|loading(?!.*\?.*:) (loading without conditional render)

# Missing error handling
Grep: catch.*\{[\s]*\} (empty catch blocks)
```

## Step 4: Framework-Specific Checks (React)

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Key props on lists | `.map()` returns have unique `key` prop | HIGH |
| useEffect deps | Dependency arrays are complete | HIGH |
| Memory leaks | useEffect cleanup for subscriptions/timers | HIGH |
| Inline functions | Callbacks in render memoized or stable | MEDIUM |
| Prop drilling | Excessive props passing (consider context) | LOW |

**Search patterns:**
```
# Missing keys
Grep: \.map\(.*=>.*<(?!.*key=)

# Empty dependency array with variables
Grep: useEffect\(.*\[\].*\) (then check for external variables)

# Missing cleanup
Grep: useEffect.*subscribe|addEventListener(?!.*return)
```

## Step 5: Internationalization

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Translated strings | User-visible text uses i18n, not hardcoded | HIGH |
| Translated aria-labels | Accessibility text also translated | HIGH |
| Date formatting | Dates use locale-aware formatting | MEDIUM |
| Number formatting | Numbers use locale-aware formatting | LOW |

**Search patterns:**
```
# Hardcoded user-visible strings
Grep: >[A-Z][a-z]+.*</ (text between tags, excluding i18n components)
```

## Step 6: Compile Results

```markdown
## UI Review Results

### Accessibility
| Check | Status | Details |
|-------|--------|---------|
| Keyboard accessible | PASS | All interactive elements are buttons/links |
| ARIA labels | FAIL | Modal missing aria-label (line 45) |
| Form labels | PASS | All inputs have labels |

### Design System Compliance
| Check | Status | Details |
|-------|--------|---------|
| DS components | PASS | Using design system components |
| No custom CSS | FAIL | Added inline style (line 72) |

### UX Patterns
| Check | Status | Details |
|-------|--------|---------|
| Loading states | PASS | Shows spinner during fetch |
| Error states | WARN | Error message not user-friendly |

### Framework (React)
| Check | Status | Details |
|-------|--------|---------|
| Key props | PASS | All lists have keys |
| useEffect deps | PASS | Dependencies complete |

### Issues Summary
- CRITICAL: 0
- HIGH: 2 (ARIA label, custom CSS)
- MEDIUM: 1 (error message UX)
- LOW: 0

### Recommendations
1. Add `aria-label="Close dialog"` to modal close button (line 45)
2. Replace inline style with design system spacing prop (line 72)
3. Consider more descriptive error message for users
```

## Output

- Checklist results (pass/fail/warn per item)
- Specific issues with file:line references
- Severity ratings (CRITICAL/HIGH/MEDIUM/LOW)
- Recommendations for fixes
- Note if any checks were skipped and why
