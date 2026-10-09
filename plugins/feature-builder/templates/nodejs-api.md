# Project Context - Node.js API

> This is a CLAUDE.md template for Node.js REST API projects.
> Copy this to your project root as `CLAUDE.md` and customize for your specific project.

**Project Type:** `api` (Node.js backend)

## Tech Stack

- **Runtime:** Node.js [version]
- **Language:** TypeScript / JavaScript (specify)
- **Framework:** [Express / Fastify / NestJS / Koa / Hapi]
- **Database:** [PostgreSQL / MongoDB / MySQL / DynamoDB]
- **ORM/ODM:** [Prisma / TypeORM / Sequelize / Mongoose]
- **Testing:** [Jest / Vitest / Mocha]
- **Build:** [tsc / esbuild / swc]

## Project Structure

```
src/
├── index.ts             # Entry point
├── routes/              # Route definitions
├── controllers/         # Request handlers
├── services/            # Business logic
├── models/              # Data models / entities
├── middleware/          # Express middleware
├── utils/               # Utility functions
└── types/               # TypeScript types
```

## Conventions

### File Organization
<!-- Describe your file organization patterns -->

### Naming
- Files: camelCase or kebab-case (specify)
- Classes: PascalCase
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE

### API Design
- RESTful resource naming (nouns, not verbs)
- Consistent response format
- Proper HTTP status codes

## Testing

### Commands
```bash
npm run test           # Run all tests
npm run test:watch     # Watch mode
npm run test:coverage  # With coverage
npm run lint           # ESLint
npm run typecheck      # tsc --noEmit (if TypeScript)
```

### Patterns
<!-- Describe testing approach: unit tests, integration tests, API tests -->

## API Verification

### Base URL
```
Development: http://localhost:3000
```

### Health Check
```
GET /health
GET /api/health
```

### OpenAPI Spec
<!-- Path to OpenAPI/Swagger spec if exists -->
```
./openapi.yaml
./docs/swagger.json
```

## Error Handling

### Response Format
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": []
  }
}
```

## Authentication

<!-- Describe auth approach: JWT, session, API keys, etc. -->

## Common Patterns

<!-- Document patterns specific to this codebase -->

## Useful Paths

<!-- Key file paths for quick reference -->

## External Resources

<!-- Links to documentation -->
