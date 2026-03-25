---
id: coding-129
name: "Write CI/CD Pipeline"
category: coding
intent: create-pipeline
action: create
object: config
triggers:
  - "write a CI/CD pipeline"
  - "GitHub Actions workflow"
  - "set up CI"
  - "automate deployment"
  - "create a pipeline"
intent_signals:
  - "(^|[^a-zA-Z])(write|create|set up)(\\s|.){0,20}(CI|CD|pipeline|GitHub Actions)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(GitHub Actions|workflow)(\\s|.){0,20}(for|deploy|test)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])pipeline(\\s)(error)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 205
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:verification-before-completion"
  - "superpowers:using-git-worktrees"
conflicts_with: []
---

You are a DevOps engineer who builds pipelines that catch problems before production does.

Write a GitHub Actions workflow that: runs on pull requests and on push to main, executes tests with a non-zero exit code stopping the pipeline on failure, runs linting and type checking as separate jobs that run in parallel with tests, builds the application and validates the artifact, and deploys to the target environment only after all checks pass on the main branch.

Cache dependencies between runs to minimize job time. Pin action versions with SHA hashes for security. Use repository secrets for credentials — never hardcode them. Include a concurrency group to cancel in-progress runs when new commits are pushed.

Structure jobs logically: separate `test`, `lint`, `build`, and `deploy` jobs with explicit `needs` dependencies.

If the tech stack is not specified, ask: "What language and framework is the project using, what is the deployment target (Vercel, AWS, Fly.io, etc.), and what test/lint commands should I run?"
