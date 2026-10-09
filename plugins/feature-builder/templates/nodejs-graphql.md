# Project Context - Node.js GraphQL

> This is a CLAUDE.md template for Node.js GraphQL API projects (Apollo Server).
> Copy this to your project root as `CLAUDE.md` and customize for your specific project.

**Project Type:** `graphql` (Apollo Server)

## Tech Stack

- **Runtime:** Node.js [version]
- **Language:** TypeScript / JavaScript (specify)
- **GraphQL Server:** [Apollo Server / GraphQL Yoga / Mercurius]
- **Schema:** [SDL-first / Code-first (TypeGraphQL, Nexus)]
- **Database:** [PostgreSQL / MongoDB / MySQL / DynamoDB]
- **ORM/ODM:** [Prisma / TypeORM / Sequelize / Mongoose]
- **Testing:** [Jest / Vitest]
- **Build:** [tsc / esbuild / swc]

## Project Structure

```
src/
├── index.ts             # Entry point, server setup
├── schema/              # GraphQL schema definitions
│   ├── typeDefs/        # SDL type definitions
│   └── resolvers/       # Resolver implementations
├── dataSources/         # Data source classes
├── services/            # Business logic
├── models/              # Data models / entities
├── loaders/             # DataLoader instances (N+1 prevention)
├── context/             # Context creation
├── utils/               # Utility functions
└── types/               # TypeScript types
```

## Conventions

### Schema Design
- Types: PascalCase (`User`, `Order`)
- Fields: camelCase (`createdAt`, `userId`)
- Enums: UPPER_SNAKE_CASE values (`PENDING`, `CONFIRMED`)
- Inputs: PascalCase with `Input` suffix (`CreateUserInput`)
- Use non-null (!) intentionally

### Resolver Patterns
- Keep resolvers thin - delegate to services
- Use DataLoader for batching (N+1 prevention)
- Authorization in resolvers, not schema

## Testing

### Commands
```bash
npm run test           # Run all tests
npm run test:watch     # Watch mode
npm run test:coverage  # With coverage
npm run lint           # ESLint
npm run typecheck      # tsc --noEmit (if TypeScript)
npm run codegen        # Generate types from schema (if applicable)
```

### Patterns
<!-- Describe testing approach: resolver tests, integration tests -->

## GraphQL Verification

### Endpoint
```
Development: http://localhost:4000/graphql
Playground:  http://localhost:4000/graphql (if enabled)
```

### Introspection
```graphql
query {
  __schema {
    types { name }
  }
}
```

### Schema Location
```
./schema.graphql
./src/schema/**/*.graphql
```

## Error Handling

### GraphQL Errors
```javascript
// Use Apollo error types
throw new AuthenticationError('Must be logged in');
throw new UserInputError('Invalid email', { field: 'email' });
throw new ForbiddenError('Not authorized');
```

### Error Response Format
```json
{
  "errors": [
    {
      "message": "Must be logged in",
      "extensions": {
        "code": "UNAUTHENTICATED"
      }
    }
  ]
}
```

## Authentication

<!-- Describe auth approach: JWT in headers, session, etc. -->

### Context Setup
```typescript
// Example context creation
const context = ({ req }) => ({
  user: getUserFromToken(req.headers.authorization),
  loaders: createLoaders(),
});
```

## Performance

### DataLoader Pattern
```typescript
// Prevent N+1 queries
const userLoader = new DataLoader(async (ids) => {
  const users = await User.findByIds(ids);
  return ids.map(id => users.find(u => u.id === id));
});
```

### Query Complexity
<!-- Describe complexity limits if configured -->

## Common Patterns

<!-- Document patterns specific to this codebase -->

## Useful Paths

<!-- Key file paths for quick reference -->

## External Resources

<!-- Links to documentation -->
