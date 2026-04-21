# Demo 03: CI/CD with GitHub Actions

**Time: ~3 minutes (show workflow file, explain, show run)**

## What You'll Show

1. GitHub Actions workflow that tests against DocumentDB emulator
2. No cloud costs for CI
3. Same connection string pattern as local and production

## Steps

### 1. Show the Workflow

Open `.github/workflows/ci.yml` and walk through:

- DocumentDB runs as a **service container** alongside the test runner
- Tests use `MONGODB_URI` environment variable (same as local dev)
- Pipeline: push → test against real DocumentDB → build → deploy

### 2. Show a Passing Run

Navigate to the Actions tab on GitHub to show green builds.

### 3. Key Points

- **Zero cloud cost** for CI — emulator runs in the GitHub Actions runner
- **Real DocumentDB** — not a mock, same engine as production
- **Fast feedback** — tests run against actual database behavior
- Same data import scripts work in CI and local

## Talking Points

- "Your CI pipeline tests against the real thing, not a mock"
- "This is the same DocumentDB engine you'll deploy to Kubernetes"
- "No Azure or AWS subscription needed for CI"
