# API Verification Reference

Verify that API implementation meets acceptance criteria through endpoint testing and contract validation.

## Inputs

- Acceptance criteria (from requirements.md)
- API base URL (from CLAUDE.md or detected)
- OpenAPI spec path (optional, from CLAUDE.md or detected)
- Auth configuration (from CLAUDE.md)

## Step 1: Detect API Configuration

**Check CLAUDE.md for:**
- `apiBaseUrl` - e.g., `http://localhost:8080`
- `authHeader` - e.g., `Authorization: Bearer $TOKEN`
- `openApiSpec` - e.g., `./openapi.yaml`

**If not in CLAUDE.md, check common locations:**
```bash
# OpenAPI spec locations
ls openapi.yaml swagger.json api.yaml 2>/dev/null
ls src/main/resources/*.yaml 2>/dev/null
ls docs/api*.yaml 2>/dev/null
```

**If base URL not found, ask user:**
```
Use AskUserQuestion:
  Question: "What is the API base URL for testing?"
  Options:
    1. "http://localhost:8080" - Common default
    2. "http://localhost:3000" - Node.js default
    3. "Other" - I'll provide the URL
    4. "Skip API verification" - Proceed without endpoint testing
```

## Step 2: Health Check

```bash
curl -s -o /dev/null -w "%{http_code}" {base_url}/health
# or common alternatives
curl -s -o /dev/null -w "%{http_code}" {base_url}/actuator/health
curl -s -o /dev/null -w "%{http_code}" {base_url}/api/health
```

**If not 200:**
```
Use AskUserQuestion:
  Question: "API health check failed (status: {code}). Is the server running?"
  Options:
    1. "Start it now" - I'll start the server and retry
    2. "Different health endpoint" - I'll provide the correct endpoint
    3. "Skip health check" - Proceed anyway
    4. "Cancel verification" - Cannot proceed without API
```

## Step 3: Verify Each Criterion

For each acceptance criterion involving API behavior:

**Parse criterion to determine:**
- HTTP method (GET, POST, PUT, DELETE)
- Endpoint path
- Request body (if applicable)
- Expected response

**Execute request:**
```bash
curl -X {METHOD} {base_url}{path} \
  -H "Content-Type: application/json" \
  {auth_header} \
  -d '{request_body}' \
  -w "\n%{http_code}" \
  -s
```

**Verify:**
- Status code matches expected (200, 201, 204, etc.)
- Response body contains expected data
- Side effects occurred (follow-up GET to verify persistence)

**Example:**
```
Criterion: "User can create a order"

1. POST /api/orders
   Body: {"itemId": 123, "startDate": "2025-01-01", "endDate": "2025-01-03"}
   Expected: 201 Created

2. GET /api/orders/{returned_id}
   Expected: 200 with order data

Result: PASS - Created order ID 456, verified retrieval
```

## Step 4: Contract Validation (if OpenAPI spec available)

If OpenAPI spec was found:

1. Validate response structure matches schema
2. Check required fields present
3. Verify error responses follow spec format
4. Flag any undocumented endpoints or fields

```
Contract validation results:
- POST /api/orders: Response matches schema
- GET /api/orders/{id}: Missing "createdAt" field (schema says required)
```

## Step 5: Compile Results

Return structured verification report:

```markdown
## API Verification Results

### Configuration
- Base URL: http://localhost:8080
- Auth: Bearer token
- OpenAPI Spec: ./openapi.yaml (validated)

### Endpoint Tests

| Criterion | Endpoint | Expected | Actual | Result |
|-----------|----------|----------|--------|--------|
| Create order | POST /api/orders | 201 | 201 | PASS |
| Get order | GET /api/orders/123 | 200 | 200 | PASS |
| Invalid input | POST /api/orders | 400 | 500 | FAIL |

### Failed Tests
- **Invalid input handling**: Expected 400 Bad Request with validation errors, got 500 Internal Server Error
  - Request: `{"itemId": "invalid"}`
  - Response: `{"error": "Internal server error"}`
  - Recommendation: Add input validation for itemId field

### Contract Violations
- GET /api/orders/{id}: Response missing required field "createdAt"

### Summary
- Passed: 2/3 criteria
- Failed: 1/3 criteria
- Contract issues: 1
```

## Output

- Verification report with pass/fail per criterion
- Request/response evidence for failures
- Contract validation results (if spec available)
- Recommendations for fixes
