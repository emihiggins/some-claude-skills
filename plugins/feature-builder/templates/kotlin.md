# Project Context - Kotlin

> This is a CLAUDE.md template for Kotlin projects.
> Copy this to your project root as `CLAUDE.md` and customize for your specific project.

**Project Type:** `api` (Kotlin backend)

## Tech Stack

- **Language:** Kotlin
- **Platform:** [Android / JVM / Multiplatform]
- **Framework:** [Android SDK / Ktor / Spring Boot]
- **Testing:** [JUnit / Kotest / MockK]
- **Build:** [Gradle / Maven]

## Project Structure

```
src/
├── main/
│   └── kotlin/
│       └── com/example/
│           ├── data/          # Data layer
│           ├── domain/        # Business logic
│           ├── presentation/  # UI (if applicable)
│           └── utils/         # Utilities
└── test/
    └── kotlin/
        └── com/example/       # Tests mirror main structure
```

## Conventions

### Architecture
<!-- MVVM / MVI / Clean Architecture / etc. -->

### Naming
- Classes: PascalCase
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE
- Packages: lowercase

### Kotlin Idioms
- Prefer `val` over `var`
- Use data classes for DTOs
- Use sealed classes for state
- Prefer extension functions over utility classes

## Testing

### Commands
```bash
./gradlew test          # Run all tests
./gradlew lint          # Lint check
./gradlew build         # Build project
```

### Patterns
<!-- Describe testing approach -->

## Common Patterns

<!-- Document patterns specific to this codebase -->

## Dependency Injection

<!-- Describe DI approach: Hilt, Koin, manual, etc. -->

## Useful Paths

<!-- Key file paths for quick reference -->

## External Resources

<!-- Links to documentation -->
