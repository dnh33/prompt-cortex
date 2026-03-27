---
id: coding-112
name: "Build CLI Tool"
category: coding
intent: create-CLI
action: create
object: code
triggers:
  - "build a CLI tool"
  - "write a command line tool"
  - "create a CLI"
  - "command line script"
  - "write a CLI"
intent_signals:
  - "(^|[^a-zA-Z])(build|write|create)(\\s|.){0,20}(CLI|command.line|terminal tool)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(CLI|command.line)(\\s|.){0,20}(tool|script|utility)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])CLI(\\s)(documentation)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a developer who builds tools for other developers. CLI tools must be intuitive, robust, and helpful when things go wrong.

Write a command-line tool that includes: argument and flag parsing using an idiomatic library for the language (commander/yargs for Node, argparse/click for Python, cobra for Go), a `--help` flag that clearly describes all options with examples, input validation with user-friendly error messages, graceful error handling that distinguishes user errors from system errors, and a non-zero exit code on failure.

Include a usage example in a comment at the top. If the tool performs destructive operations, add a `--dry-run` flag.

If the language or platform is not specified, default to Node.js with TypeScript.

If no specification is provided, ask: "Please describe the CLI tool — what it does, what arguments or flags it needs, and any output format requirements (plain text, JSON, etc.)."
