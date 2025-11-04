# Contributing Guide

## Pull Request Workflow

We use Pull Requests for all changes to the `main` branch. Here's how to contribute:

### 1. Create a Feature Branch

```bash
# Update main branch
git checkout main
git pull origin main

# Create a new branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 2. Make Your Changes

Write code, tests, and documentation:

```bash
# Make changes
# ...

# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat: add new feature"
```

### 3. Run Tests Locally

Before pushing, ensure all tests pass:

```bash
# Activate virtual environment
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Run tests
pytest -v

# Run with coverage
pytest -v --cov=app --cov-report=term

# Optional: Check code quality
black --check app/ tests/
isort --check-only app/ tests/
ruff check app/ tests/
```

### 4. Push Your Branch

```bash
git push origin feature/your-feature-name
```

### 5. Create Pull Request

1. Go to [GitHub repository](https://github.com/mholetzko/permetix)
2. Click "Pull requests" → "New pull request"
3. Select your branch
4. Fill out the PR template
5. Click "Create pull request"

### 6. CI Checks

The following checks will run automatically:

- ✅ **Test Suite** - All pytest tests must pass
- ✅ **Code Quality** - Black, isort, and Ruff linting
- ✅ **Docker Build** - Container image must build successfully
- ✅ **All Checks Passed** - Summary check

### 7. Review & Merge

- Address any failing checks
- Respond to review comments
- Once approved and all checks pass, merge the PR

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>: <description>

[optional body]

[optional footer]
```

### Types

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only changes
- `style:` - Code style changes (formatting, missing semicolons, etc.)
- `refactor:` - Code change that neither fixes a bug nor adds a feature
- `perf:` - Performance improvement
- `test:` - Adding or correcting tests
- `chore:` - Changes to build process or auxiliary tools

### Examples

```bash
feat: add overage charges table and persistence

fix: resolve cost calculation for returned licenses

docs: update deployment instructions for Fly.io

test: add tests for budget configuration endpoint

chore: update dependencies to latest versions
```

## Code Style

### Python

- **Formatting**: Black (line length 100)
- **Import sorting**: isort
- **Linting**: Ruff

Auto-format your code:

```bash
black app/ tests/
isort app/ tests/
ruff check --fix app/ tests/
```

### Frontend (HTML/CSS/JS)

- Use 2-space indentation
- Follow existing patterns
- Keep Mercedes-Benz styling consistent

## Testing

### Writing Tests

Place tests in the `tests/` directory:

```python
# tests/test_feature.py
import pytest
from app.db import some_function

def test_feature():
    result = some_function()
    assert result == expected_value
```

### Running Specific Tests

```bash
# Run specific test file
pytest tests/test_licenses.py -v

# Run specific test
pytest tests/test_licenses.py::test_borrow_and_return -v

# Run with markers
pytest -m "not slow" -v
```

## Local Development

### Setup

```bash
# Clone and setup
git clone https://github.com/mholetzko/permetix.git
cd cloud-vs-automotive-demo

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn app.main:app --reload
```

### Docker Development

```bash
# Build and run with docker-compose
docker compose up --build

# Run tests in Docker
docker compose run --rm app pytest -v
```

## Branch Protection

The `main` branch is protected. You must:

1. Create a pull request
2. Pass all CI checks
3. Get required approvals (if configured)
4. Have conversations resolved

See [.github/BRANCH_PROTECTION.md](.github/BRANCH_PROTECTION.md) for details.

## Getting Help

- Check existing issues and PRs
- Review documentation in README.md
- Look at previous commits for examples

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

