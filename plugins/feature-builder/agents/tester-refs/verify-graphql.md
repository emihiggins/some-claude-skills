# GraphQL Verification Reference

Verify that GraphQL implementation meets acceptance criteria through query/mutation execution and schema validation.

## Inputs

- Acceptance criteria (from requirements.md)
- GraphQL endpoint (from CLAUDE.md or detected)
- Schema path (optional, from CLAUDE.md or detected)
- Auth configuration (from CLAUDE.md)

## Step 1: Detect GraphQL Configuration

**Check CLAUDE.md for:**
- `graphqlEndpoint` - e.g., `http://localhost:4000/graphql`
- `authHeader` - e.g., `Authorization: Bearer $TOKEN`
- `schemaPath` - e.g., `./schema.graphql`

**If not in CLAUDE.md, check common locations:**
```bash
# Schema locations
ls schema.graphql schema.json 2>/dev/null
ls src/schema/*.graphql 2>/dev/null
ls graphql/*.graphql 2>/dev/null
```

**Common endpoint paths:**
- `/graphql`
- `/api/graphql`
- `/query`

## Step 2: Introspection Check

Verify GraphQL endpoint is accessible:

```bash
curl -X POST {endpoint} \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}' \
  -s
```

**If introspection disabled or fails:**
```
Use AskUserQuestion:
  Question: "GraphQL introspection failed. Is the server running?"
  Options:
    1. "Start it now" - I'll start the server and retry
    2. "Introspection is disabled" - Use schema file instead
    3. "Different endpoint" - I'll provide the correct endpoint
    4. "Cancel verification" - Cannot proceed
```

## Step 3: Verify Each Criterion

For each acceptance criterion involving GraphQL:

**Parse criterion to determine:**
- Query or Mutation
- Fields to request
- Variables needed
- Expected response shape

**Execute GraphQL operation:**
```bash
curl -X POST {endpoint} \
  -H "Content-Type: application/json" \
  {auth_header} \
  -d '{
    "query": "{query_string}",
    "variables": {variables_json}
  }' \
  -s
```

**Verify:**
- No errors in response
- Data matches expected shape
- Mutations persist correctly (verify with follow-up query)

**Example - Query:**
```
Criterion: "User can query orders by unit"

Query:
query GetOrders($itemId: ID!) {
  orders(itemId: $itemId) {
    id
    startDate
    endDate
    status
  }
}

Variables: {"itemId": "123"}

Expected: Array of orders with required fields
Result: PASS - Returned 3 orders with correct shape
```

**Example - Mutation:**
```
Criterion: "User can create a order"

Mutation:
mutation CreateOrder($input: OrderInput!) {
  createOrder(input: $input) {
    id
    startDate
    endDate
  }
}

Variables: {"input": {"itemId": "123", "startDate": "2025-01-01", "endDate": "2025-01-03"}}

Expected: Returns created order with ID
Verify: Follow-up query confirms persistence
Result: PASS - Created ID 456, verified via query
```

## Step 4: Schema Validation (if schema available)

If schema file was found:

1. Verify new types exist as expected
2. Check field nullability matches requirements
3. Validate input types for mutations
4. Check for breaking changes (if comparing to previous)

```
Schema validation results:
- Type "Order" exists
- Field "status" is non-null as required
- Input type "OrderInput" has all required fields
- Enum "OrderStatus" includes new value "PENDING"
```

## Step 5: Error Handling Verification

Test error scenarios:

```graphql
# Invalid ID
query { order(id: "nonexistent") { id } }
# Expected: null with no errors, OR error with proper code

# Invalid input
mutation { createOrder(input: {}) { id } }
# Expected: Validation error with field details
```

## Step 6: Compile Results

Return structured verification report:

```markdown
## GraphQL Verification Results

### Configuration
- Endpoint: http://localhost:4000/graphql
- Auth: Bearer token
- Schema: ./schema.graphql (validated)

### Query/Mutation Tests

| Criterion | Operation | Result | Notes |
|-----------|-----------|--------|-------|
| Query orders | Query | PASS | Returned expected shape |
| Create order | Mutation | PASS | Persisted correctly |
| Error handling | Query | FAIL | Returns 500 instead of null |

### Failed Tests
- **Error handling for invalid ID**: Expected null response or GraphQL error, got HTTP 500
  - Query: `{ order(id: "nonexistent") { id } }`
  - Response: HTTP 500 Internal Server Error
  - Recommendation: Add null check in resolver

### Schema Validation
- All required types present
- Nullability correct
- No breaking changes detected

### Summary
- Passed: 2/3 criteria
- Failed: 1/3 criteria
- Schema valid: Yes
```

## Output

- Verification report with pass/fail per criterion
- Query/mutation results as evidence
- Schema validation results
- Error handling assessment
- Recommendations for fixes
