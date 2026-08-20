# Project Context - TypeScript

> This is a CLAUDE.md template for TypeScript projects.
> Copy this to your project root as `CLAUDE.md` and customize for your specific project.

**Project Type:** `api` (TypeScript backend)
<!-- Change to `ui` if this is a frontend project, or `graphql` if GraphQL API -->

## Tech Stack

- **Language:** TypeScript
- **Runtime:** [Node.js / Deno / Bun]
- **Framework:** [Express / Fastify / NestJS / None]
- **Testing:** [Jest / Vitest / Mocha]
- **Build:** [tsc / esbuild / swc]

## Project Structure

```
src/
├── index.ts             # Entry point
├── services/            # Business logic
├── controllers/         # Request handlers (if web)
├── models/              # Data models
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

## Testing

### Commands
```bash
npm run test           # Run all tests
npm run lint           # ESLint
npm run typecheck      # tsc --noEmit
npm run build          # Build project
```

### Patterns
<!-- Describe testing approach -->

## Common Patterns

<!-- Document patterns specific to this codebase -->

## Error Handling

<!-- Describe error handling approach -->

## Useful Paths

<!-- Key file paths for quick reference -->

## External Resources

<!-- Links to documentation -->
