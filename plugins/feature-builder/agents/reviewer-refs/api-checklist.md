# API Review Checklist

Supplement standard code review with API-specific checks for REST conventions, security, and contract compliance.

## Inputs

- Files changed (from review context)
- API framework (from CLAUDE.md, e.g., "Spring Boot", "Dropwizard", "Express", "Hapi", "FastAPI", "Flask")
- OpenAPI spec path (from CLAUDE.md, if exists)

## Step 1: REST Conventions Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| HTTP methods | GET=read, POST=create, PUT=update, DELETE=delete | HIGH |
| Resource URLs | Nouns not verbs (`/users` not `/getUsers`) | HIGH |
| Status codes | Correct codes (201 create, 204 delete, 400 bad input, etc.) | HIGH |
| Plural resources | Collections are plural (`/users` not `/user`) | MEDIUM |
| URL parameters | IDs in path, filters in query string | MEDIUM |
| Consistent naming | camelCase or snake_case throughout, not mixed | LOW |

**Search patterns:**
```
# Verbs in URLs
Grep: @(Get|Post|Put|Delete)Mapping.*/(get|create|update|delete|fetch)

# Wrong status codes
Grep: return.*200.*create|return.*200.*delete

# Inconsistent naming
Grep: "[a-z]+_[a-z]+.*[a-z]+[A-Z]" (mixed case in same response)
```

## Step 2: Security Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Input validation | All inputs validated before use | CRITICAL |
| SQL injection | Parameterized queries, no string concat | CRITICAL |
| Authentication | Protected endpoints require auth | CRITICAL |
| Authorization | Users can only access own resources | CRITICAL |
| Sensitive data | No secrets in URLs, logs, or responses | HIGH |
| Rate limiting | High-volume endpoints have limits | MEDIUM |
| CORS | Appropriate CORS headers if needed | MEDIUM |

**Search patterns:**
```
# SQL injection risk
Grep: execute.*\+.*\"|query.*\+.*\"|\"SELECT.*\+

# Missing auth
Grep: @(Get|Post|Put|Delete)Mapping(?!.*@Secured|@PreAuthorize|@Auth)

# Sensitive data in logs
Grep: log\.(info|debug|error).*password|log.*token|log.*secret

# Hardcoded secrets
Grep: password.*=.*\"|api_key.*=.*\"|secret.*=.*\"
```

## Step 3: Error Handling Review

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Consistent error format | All errors return same structure | HIGH |
| Meaningful error codes | Error codes are documented/useful | HIGH |
| No stack traces | Production doesn't leak stack traces | HIGH |
| Validation errors | Include field names in validation errors | MEDIUM |
| Error logging | Errors are logged with context | MEDIUM |

**Expected error format:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {"field": "email", "message": "Invalid email format"}
    ]
  }
}
```

## Step 4: API Contract Review

**If OpenAPI spec exists:**

| Check | How to Verify | Severity |
|-------|--------------|----------|
| Spec updated | New endpoints documented in spec | HIGH |
| Response matches | Response DTO matches spec schema | HIGH |
| Request matches | Request DTO matches spec schema | HIGH |
| Error responses | Error codes documented in spec | MEDIUM |
| Breaking changes | No removed fields, changed types | CRITICAL |

## Step 5: Performance Considerations

| Check | How to Verify | Severity |
|-------|--------------|----------|
| N+1 queries | Batch fetches, not loops of queries | HIGH |
| Pagination | List endpoints support pagination | HIGH |
| Caching headers | Appropriate Cache-Control headers | MEDIUM |
| Async operations | Long operations are async | MEDIUM |
| Database indexes | Queried fields are indexed | LOW |

## Step 6: Framework-Specific Checks

**Spring Boot:**
```
# Missing validation
Grep: @RequestBody(?!.*@Valid)

# Missing transaction
Grep: (save|update|delete).*repository(?!.*@Transactional)
```

**Dropwizard:**
```
# Missing validation
Grep: @(POST|PUT).*(?!.*@Valid)

# Missing metrics/healthchecks
Grep: class.*Resource(?!.*@Timed)
```

**Express/Hapi/Node:**
```
# Missing async error handling
Grep: async.*req.*res(?!.*try|.*catch|.*next)

# Missing input sanitization
Grep: req\.body\.|req\.params\.(?!.*sanitize|.*validate)

# Hapi: Missing Joi validation
Grep: handler.*(?!.*validate)
```

**FastAPI/Flask:**
```
# Missing type hints (FastAPI)
Grep: def.*\(.*request(?!.*:)

# Missing input validation
Grep: request\.(json|form|args)(?!.*validate)
```

## Step 7: Compile Results

```markdown
## API Review Results

### REST Conventions
| Check | Status | Details |
|-------|--------|---------|
| HTTP methods | PASS | Correct methods used |
| Resource URLs | FAIL | `/getUser` should be `/users/{id}` |

### Security
| Check | Status | Details |
|-------|--------|---------|
| Input validation | PASS | All inputs validated |
| Authorization | FAIL | Missing ownership check (line 45) |

### Issues Summary
- CRITICAL: 1 (authorization)
- HIGH: 2 (URL naming, spec update)

### Recommendations
1. CRITICAL: Add ownership check before returning user data (line 45)
2. Rename endpoint from `/getUser/{id}` to `/users/{id}`
```

## Output

- Checklist results (pass/fail/warn per item)
- Security issues flagged with severity
- Contract compliance assessment
- Specific issues with file:line references
- Recommendations for fixes
