# GraphQL Review Checklist

Supplement standard code review with GraphQL-specific checks for schema design, performance, and resolver best practices.

## Inputs

- Files changed (from review context)
- GraphQL framework (from CLAUDE.md, e.g., "Apollo Server", "Apollo Federation", "graphql-js", "Nexus", "TypeGraphQL")
- Schema path (from CLAUDE.md)

## Step 1: Schema Design Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Type naming | Types are PascalCase, descriptive | MEDIUM |
| Field naming | Fields are camelCase | MEDIUM |
| Nullability | Non-null (!) is intentional, nullable by default | HIGH |
| Input types | Mutations use input types, not inline args | HIGH |
| Connections | Paginated lists use Connection pattern | HIGH |
| Descriptions | Types and fields have descriptions | LOW |
| Enums | Fixed value sets use enums | MEDIUM |

## Step 2: Performance Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| N+1 prevention | DataLoader used for batching | CRITICAL |
| Depth limiting | Query depth is limited | HIGH |
| Complexity analysis | Complex queries have cost limits | HIGH |
| No unbounded lists | Pagination required for lists | HIGH |
| Field-level caching | Expensive fields cached | MEDIUM |

## Step 3: Resolver Patterns Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Thin resolvers | Business logic in services, not resolvers | HIGH |
| Error handling | Errors use GraphQL error types | HIGH |
| Authorization | Auth checks in resolvers | CRITICAL |
| Context usage | Context not mutated, used correctly | MEDIUM |
| Validation | Input validated before processing | HIGH |

## Step 4: Breaking Changes Detection

| Check | How to Verify | Severity |
|-------|--------------|----------|
| No removed fields | Fields deprecated, not removed | CRITICAL |
| No type changes | Return types not changed | CRITICAL |
| No required args added | New args have defaults | HIGH |
| Deprecations documented | @deprecated directive used | MEDIUM |

## Step 5: Security Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Query depth limit | Prevents deeply nested attacks | HIGH |
| Query complexity | Prevents expensive query attacks | HIGH |
| Introspection | Disabled in production (optional) | MEDIUM |
| Field authorization | Sensitive fields protected | CRITICAL |
| Input sanitization | Inputs sanitized before use | HIGH |

## Step 6: Testing Coverage

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Resolver tests | Each resolver has tests | HIGH |
| Error case tests | Error scenarios tested | HIGH |
| Integration tests | Full query execution tested | MEDIUM |
| Schema tests | Schema changes validated | LOW |

## Step 7: Compile Results

```markdown
## GraphQL Review Results

### Schema Design
| Check | Status | Details |
|-------|--------|---------|
| Type naming | PASS | All types PascalCase |
| Nullability | WARN | Consider if `status` should be non-null |

### Performance
| Check | Status | Details |
|-------|--------|---------|
| N+1 prevention | FAIL | Missing DataLoader for Unit (line 45) |

### Issues Summary
- CRITICAL: 2 (N+1, field auth)
- HIGH: 1 (unbounded list)

### Recommendations
1. CRITICAL: Add DataLoader for Unit lookups to prevent N+1
2. CRITICAL: Protect `user.email` field with @auth directive
```

## Output

- Checklist results (pass/fail/warn per item)
- Performance issues flagged
- Breaking changes detected
- Security concerns
- Specific issues with file:line references
- Recommendations for fixes
