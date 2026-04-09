---
name: python
description: >
  Use this skill any time Python code needs to be written, run, debugged, or managed in any form.
  This includes: running Python scripts, executing one-off Python snippets, installing or listing
  packages, setting up a new Python project, working with virtual environments, debugging Python
  errors, writing Python utilities, data processing scripts, or automation code. ALWAYS use this
  skill when the user asks to run Python, install a pip/Python package, write a script, or work
  with any .py file. Also trigger when the user wants to "try something in Python", "add a
  dependency", or "set up a Python project" — even if they don't explicitly mention uv or venv.
---

# Python Skill — uv-Centered Workflow

All Python work in this skill uses **uv** as the single tool for environment management, running code, and package operations. Never use bare `python`, `pip`, or `virtualenv` commands unless the user explicitly asks for a different approach.

---

## Step 1: Locate or Create the Virtual Environment

Before running any Python code or installing any package, find or create a `.venv`.

### Discovery order (follow this exactly):

1. **Check the current working directory** for a `.venv` folder:
   ```bash
   ls .venv 2>/dev/null && echo "found"
   ```

2. **If not found, walk up to the git project root** and check there:
   ```bash
   git rev-parse --show-toplevel 2>/dev/null
   # then check <git-root>/.venv
   ```

3. **If still not found, create one** in the current working directory using uv:
   ```bash
   uv venv
   ```
   This creates `.venv/` in the current directory. No need to activate it — uv handles activation automatically when you prefix commands with `uv run`.

**Why this order matters**: Projects often have their venv at the repo root rather than in a subdirectory. Checking the git root prevents creating duplicate environments.

---

## Step 2: Running Python Code

Always use `uv run` — it automatically uses the `.venv` in the current or parent directory (up to the project root), so you never need to activate manually.

```bash
# Run a script
uv run python script.py

# Run a one-liner
uv run python -c "import sys; print(sys.version)"

# Run a module
uv run python -m pytest
uv run python -m http.server 8000
```

**If the venv is in a parent directory** (git root), uv will find it automatically. You don't need to `cd` there first.

---

## Step 3: Managing Packages

### Installing packages

```bash
# Standard install — adds to pyproject.toml if present
uv add requests
uv add pandas numpy matplotlib

# Install a specific version
uv add "fastapi>=0.100"

# Install dev-only dependency
uv add --dev pytest ruff mypy

# Install from a git repo
uv add git+https://github.com/org/repo.git
```

**When to use `uv pip install` instead of `uv add`**:
- The user explicitly asks for `pip install` behavior
- There is no `pyproject.toml` and you're doing a quick one-off install (not a project)
- Installing into the venv without modifying any project file

```bash
# One-off install without modifying pyproject.toml
uv pip install requests
```

### Listing installed packages

```bash
uv pip list
```

### Removing packages

```bash
uv remove requests
```

### Syncing dependencies (after cloning a project)

```bash
# Install all dependencies from pyproject.toml / requirements files
uv sync
```

---

## Project Initialization

When the user wants a new Python project from scratch:

```bash
# Create a new project with pyproject.toml + venv
uv init my-project
cd my-project

# Or init in current directory
uv init
```

This creates:
- `pyproject.toml` with project metadata
- `.venv/` virtual environment
- `hello.py` starter script (can be deleted)

For a library (as opposed to a script/app):
```bash
uv init --lib my-library
```

---

## Common Workflows

### Debug a script that's failing

```bash
# Run with verbose traceback
uv run python -tb script.py

# Or just run normally — uv shows the full traceback
uv run python script.py
```

### Run tests

```bash
uv run python -m pytest
uv run python -m pytest tests/test_foo.py -v
uv run python -m pytest -x  # stop on first failure
```

### Format and lint

```bash
uv run ruff check .
uv run ruff format .
uv run mypy .
```

### Interactive REPL

```bash
uv run python
# or with ipython if installed
uv run ipython
```

---

## Environment Inspection

```bash
# Which Python is in use
uv run python --version

# Where is the venv
uv run python -c "import sys; print(sys.prefix)"

# List all installed packages
uv pip list

# Show details about a specific package
uv pip show requests

# Check if a package is installed
uv pip show pandas && echo "installed" || echo "not installed"
```

---

## Quick Reference

| Goal | Command |
|---|---|
| Create venv | `uv venv` |
| Run a script | `uv run python script.py` |
| Install a package | `uv add <package>` |
| Install dev dep | `uv add --dev <package>` |
| List packages | `uv pip list` |
| Remove a package | `uv remove <package>` |
| Sync dependencies | `uv sync` |
| New project | `uv init` |
| Run tests | `uv run python -m pytest` |
| Run linter | `uv run ruff check .` |

---

## Important Rules

- **Never use bare `python` or `pip`** — always prefix with `uv run` / `uv add` / `uv pip`.
- **Never activate the venv manually** (`source .venv/bin/activate`) — uv makes this unnecessary and it introduces fragility.
- **Always discover before creating** — check for an existing `.venv` at cwd and git root before making a new one.
- **Prefer `uv add` over `uv pip install`** for project dependencies — it keeps `pyproject.toml` in sync.
- **Use `uv sync`** when picking up someone else's project that already has a `pyproject.toml`.
