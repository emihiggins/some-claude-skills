# Project Context - Python

> This is a CLAUDE.md template for Python projects.
> Copy this to your project root as `CLAUDE.md` and customize for your specific project.

**Project Type:** `api` (Python backend)
<!-- Change to `graphql` if GraphQL API -->

## Tech Stack

- **Language:** Python [version]
- **Framework:** [Django / FastAPI / Flask / None]
- **Testing:** [pytest / unittest]
- **Package Manager:** [pip / poetry / uv]
- **Linting:** [ruff / flake8 / pylint]
- **Type Checking:** [mypy / pyright] (if applicable)

## Project Structure

```
src/
├── __init__.py
├── main.py              # Entry point
├── services/            # Business logic
├── models/              # Data models
├── api/                 # API routes (if web)
└── utils/               # Utility functions

tests/
├── conftest.py          # Pytest fixtures
├── test_services/
└── test_models/
```

## Conventions

### File Organization
<!-- Describe your file organization patterns -->

### Naming
- Files: snake_case
- Classes: PascalCase
- Functions: snake_case
- Constants: UPPER_SNAKE_CASE

### Style
- Follow PEP 8
- Maximum line length: [79 / 88 / 120]
- Use type hints

## Testing

### Commands
```bash
pytest                  # Run all tests
pytest -v               # Verbose
pytest --cov            # With coverage
ruff check .            # Lint
mypy .                  # Type check (if applicable)
```

### Patterns
<!-- Describe testing approach -->

## Common Patterns

<!-- Document patterns specific to this codebase -->

## Environment

```bash
# Virtual environment
python -m venv venv
source venv/bin/activate  # or: venv\Scripts\activate (Windows)

# Install dependencies
pip install -r requirements.txt
# or: poetry install
```

## Useful Paths

<!-- Key file paths for quick reference -->

## External Resources

<!-- Links to documentation -->
