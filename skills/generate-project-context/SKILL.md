---
name: generate-project-context
description: "Generate or set up a project's CLAUDE.md by auto-scanning the tech stack, applying a stack template (React, Node, Python, Kotlin, minimal, etc.), or walking the user through guided creation. Ensures downstream workflow agents have the tech stack, test commands, and conventions they need. Use when the user asks to 'set up CLAUDE.md', 'generate project context', 'add a CLAUDE.md for this repo', or when a workflow flags the project as missing context. NOT for updating an existing CLAUDE.md (edit directly) and NOT for global user-level Claude memory (use ~/.claude/CLAUDE.md manually)."
argument-hint: "[generate|generate --asset|template|check]"
---

# Generate Project Context

Create a `CLAUDE.md` file that tells agents about your tech stack, project structure, testing commands, and conventions. This is essential for all workflow agents to produce quality output.

## Modes

| Mode | Trigger | What It Does |
|------|---------|--------------|
| `generate` (default) | "generate CLAUDE.md", "set up project context" | Auto-scan project and generate tailored CLAUDE.md |
| `generate --asset` | "generate for this asset" | Auto-scan for a monorepo asset folder (scoped, references parent) |
| `template` | "create from template", "use a template" | Interactive template selection for your stack |
| `check` | "check CLAUDE.md", "verify project setup" | Validate existing CLAUDE.md has required fields |

## Mode: Generate (Auto-Scan)

Scan **ONLY the current working directory** (the target project) and generate CLAUDE.md automatically. Use Glob, Read, and Grep (no Bash) to detect:

**Scope restriction:** Only scan files in the current working directory. Do NOT scan reference repos, sibling directories, or parent directories.

1. **Build system**: `Glob("build.gradle*")`, `Glob("pom.xml")`, `Glob("package.json")`, `Glob("pyproject.toml")`
2. **Language**: Check file extensions in `src/` — `Glob("src/**/*.kt")`, `Glob("src/**/*.java")`, `Glob("src/**/*.ts")`, etc.
3. **Framework**: Read the build file to find dependencies (Spring Boot, Dropwizard, React, Express, etc.)
4. **Project structure**: `Glob("src/main/*")`, `Glob("src/test/*")`, `Glob("src/components/*")`
5. **Test commands**: Read build file for test tasks/scripts
6. **Existing patterns**: Read 2-3 source files to understand conventions

Write `CLAUDE.md` in the current working directory with **stack-specific Architecture Principles**:

**Base structure (all projects):**
```markdown
# {Project Name}

**Project Type:** `{ui|api|graphql}`

## Tech Stack
- Language: {detected}
- Framework: {detected}
- Build: {detected}

## Project Structure
{detected layout}

## Build & Test Commands
- Build: {from build file}
- Test: {from build file}
- Lint: {from build file}

## Conventions
{patterns observed from source files}
```

**CRITICAL: Add stack-specific Architecture Principles section based on detected project type:**

### If React/UI Project Detected

Add this section after "## Tech Stack" (copy from templates/react-generic.md):

```markdown
## Architecture Principles

### Atomic Component Decomposition

**Break complex components into small, focused pieces:**

- **One responsibility per component** - Each component should do one thing well
- **Extract sub-components** when a component has distinct visual sections (header, body, footer) or logical groupings
- **File splitting threshold** - If a component file exceeds ~200 lines, evaluate for decomposition
- **Reusability indicator** - If a piece could be used elsewhere (even hypothetically), extract it

**Example - Bad (monolithic):**
```tsx
// FormComponent.tsx (350 lines)
export const FormComponent = () => {
  // All logic, types, constants, and sub-components in one file
}
```

**Example - Good (atomic):**
```tsx
// FormComponent/
//   index.tsx              - Main component (orchestrates)
//   FormSection1.tsx       - Section 1 UI
//   FormSection2.tsx       - Section 2 UI
//   FormField.tsx          - Single field (reusable)
//   types.ts               - Shared types
//   constants.ts           - Dropdown options, config
//   useFormState.ts        - Custom hook for state logic
```

### Separation of Concerns

**Extract into separate files when:**

1. **Types** - 5+ type definitions or any type used by multiple components → `types.ts`
2. **Constants** - 3+ constant arrays/objects (options, config, mappings) → `constants.ts`
3. **Hooks** - Any complex useState/useReducer/useEffect logic → `use*.ts` custom hook
4. **Utilities** - Pure functions (formatters, validators, calculations) → `utils.ts` or shared utils/
5. **Sub-components** - Any component rendered by parent → separate `.tsx` file

**Do NOT extract:**
- Single type used only in one component
- 1-2 small constants (keep co-located)
- Trivial JSX fragments (< 10 lines)

### Lego Pattern

**Components should compose like Lego blocks:**

- **Props over configuration** - Pass data down, not global config
- **Controlled components** - Parent owns state, child renders and emits events
- **Composition over inheritance** - Use `children` prop and composition
- **Single source of truth** - State lives at the lowest common ancestor
```

### If Kotlin/JVM Project Detected

Add this section after "## Tech Stack":

```markdown
## Architecture Principles

### SOLID Principles

All code should follow SOLID principles:
- **Single Responsibility** - Each class has one reason to change
- **Open/Closed** - Open for extension, closed for modification
- **Liskov Substitution** - Subtypes must be substitutable for base types
- **Interface Segregation** - Clients shouldn't depend on interfaces they don't use
- **Dependency Inversion** - Depend on abstractions, not concretions

### Onion Architecture

Follow onion architecture layers:
- **Domain** (core) - Business logic, entities, value objects
- **Application** - Use cases, orchestration, DTOs
- **Infrastructure** - Database, external APIs, frameworks
- **Presentation** - REST endpoints, GraphQL resolvers

Dependencies point inward: Presentation → Application → Domain

### Package Structure

```
src/main/kotlin/
  domain/           # Core business logic (no framework dependencies)
    model/          # Entities, value objects
    service/        # Domain services
  application/      # Use cases, application services
    usecase/        # Business operations
    port/           # Interfaces for infrastructure
  infrastructure/   # Technical concerns
    persistence/    # Database adapters
    rest/           # REST clients
  presentation/     # API layer
    rest/           # REST endpoints
    graphql/        # GraphQL resolvers (if applicable)
```
```

**If projectType cannot be auto-detected**, ask:
```
Use AskUserQuestion:
  Question: "What type of project is this?"
  Header: "Project type"
  Options:
    1. "UI" - Frontend app (React, Angular, Vue, etc.)
    2. "API" - Backend service (REST, Kotlin, Node.js, etc.)
    3. "GraphQL" - GraphQL server (Apollo, schema-first, etc.)
    4. "Other" - Not sure or doesn't fit above categories
```

Output: "Generated CLAUDE.md from your project. Please review it — you can edit it anytime to add more context."

## Mode: Generate --asset (Monorepo Asset)

When the `--asset` flag is present, generate a CLAUDE.md **scoped to this specific asset/package** within a monorepo. The parent monorepo may have its own CLAUDE.md with shared conventions — this asset CLAUDE.md adds package-specific details.

**Scan the same way as regular generate mode**, but:

1. **Scope is this folder only** — do NOT scan parent directories or sibling packages
2. **Check for parent CLAUDE.md** — use `git rev-parse --show-toplevel` to find the repo root, check if `CLAUDE.md` or `.claude/CLAUDE.md` exists there
3. **Reference the parent** — if parent CLAUDE.md exists, add a note at the top:

```markdown
# {Package Name}

> This asset is part of a monorepo. See the root `CLAUDE.md` for shared conventions.
> This file covers **this package's** specific structure, commands, and conventions.

**Project Type:** `{ui|api|graphql}`
```

4. **Focus on what differs from root:**
   - This package's specific build/test/lint commands (may differ from root)
   - This package's directory structure
   - This package's specific dependencies and framework version
   - Any conventions unique to this package

5. **Write to `./CLAUDE.md`** in the current working directory (the asset folder)

**Example output for a React package in a monorepo:**

```markdown
# Example UI App

> This asset is part of a monorepo. See the root `CLAUDE.md` for shared conventions.
> This file covers **this package's** specific structure, commands, and conventions.

**Project Type:** `ui`

## Tech Stack
- React 18 with TypeScript
- Design System (check CLAUDE.md for design system MCP tools)
- Vite for bundling

## Project Structure
src/
  components/       # React components
  hooks/            # Custom hooks
  utils/            # Utility functions
  __tests__/        # Test files

## Build & Test Commands
- Dev server: `pnpm dev` (runs on port 8002)
- Test: `pnpm test`
- Lint: `pnpm lint`
- Type check: `pnpm type-check`
- Build: `pnpm build`

## Conventions
- Component files use PascalCase
- Test files co-located in __tests__/ directories
- Design system components preferred over custom UI
```

Output: "Generated asset-level CLAUDE.md for this package. The root CLAUDE.md still applies for shared monorepo conventions."

## Mode: Template

Two-step selection (AskUserQuestion supports max 4 options, so narrow by category first).

**Step A — Category:**
```
Use AskUserQuestion:
  Question: "What kind of project is this?"
  Header: "Stack"
  Options:
    1. "Frontend (React, UI)" - React with or without a design system
    2. "Backend (API, service)" - Kotlin, Node.js, TypeScript backend
    3. "Python" - Python application or service
    4. "Minimal" - Just basic structure, fill in details yourself
```

**Step B — Specific template (if Frontend or Backend):**

If "Frontend":
```
Use AskUserQuestion:
  Question: "Which frontend template?"
  Header: "Template"
  Options:
    1. "React (generic)" - Standard React app
```

If "Backend":
```
Use AskUserQuestion:
  Question: "Which backend template?"
  Header: "Template"
  Options:
    1. "Kotlin (Spring Boot / Ktor)" - JVM backend with Gradle
    2. "Node.js REST API" - Express/Fastify REST service
    3. "Node.js GraphQL" - Apollo GraphQL server
    4. "TypeScript (generic)" - General TypeScript project
```

**Template mapping:**

| Choice | Template File | projectType |
|--------|--------------|-------------|
| React (generic) | `templates/react-generic.md` | ui |
| Kotlin | `templates/kotlin.md` | api |
| Node.js REST | `templates/nodejs-api.md` | api |
| Node.js GraphQL | `templates/nodejs-graphql.md` | graphql |
| TypeScript | `templates/typescript-generic.md` | api |
| Python | `templates/python.md` | api |
| Minimal | `templates/minimal.md` | unknown |

Read the template from `${CLAUDE_PLUGIN_ROOT}/templates/{template}.md`, write to `./CLAUDE.md`.

Output: "Created CLAUDE.md from {template} template. Review and customize it, then continue."

Offer to continue or customize:
```
Use AskUserQuestion:
  Question: "Ready to continue, or do you want to customize CLAUDE.md first?"
  Header: "Continue?"
  Options:
    1. "Continue now" - Proceed with the template as-is
    2. "Let me customize first" - I'll edit CLAUDE.md manually
```

## Mode: Check

Validate an existing CLAUDE.md has the fields agents need:

1. Read `CLAUDE.md` (or `.claude/CLAUDE.md`)
2. Check for required fields:
   - `Project Type` declaration
   - Build/test commands
   - Tech stack info
3. Report what's missing
4. Offer to fill in gaps interactively

## Output Contract

```
STATUS: complete | incomplete | skipped
CLAUDE_MD_PATH: {path to CLAUDE.md}
PROJECT_TYPE: {ui|api|graphql|unknown}
MODE: {generate|template|check}
```
