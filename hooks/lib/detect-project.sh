#!/usr/bin/env bash
# detect-project.sh — Shared project detection (sourced by hooks)
# Usage: source this file, then call: detect_project [dir]
# Output: space-separated: language framework testing linter pkgmgr monorepo branch_type

detect_project() {
  local project_dir="${1:-${CLAUDE_PROJECT_DIR:-.}}"
  local language="unknown"
  local framework="unknown"
  local testing=""
  local linter=""
  local pkgmgr=""
  local monorepo="false"
  local branch_type=""

  # Language detection
  if [[ -f "${project_dir}/package.json" ]]; then
    language="javascript"
    if [[ -f "${project_dir}/tsconfig.json" ]]; then
      language="typescript"
    fi
    # Framework detection
    if grep -q '"next"' "${project_dir}/package.json" 2>/dev/null; then
      framework="nextjs"
    elif grep -q '"react"' "${project_dir}/package.json" 2>/dev/null; then
      framework="react"
    elif grep -q '"vue"' "${project_dir}/package.json" 2>/dev/null; then
      framework="vue"
    elif grep -q '"svelte"' "${project_dir}/package.json" 2>/dev/null; then
      framework="svelte"
    elif grep -q '"express"' "${project_dir}/package.json" 2>/dev/null; then
      framework="express"
    fi
  elif [[ -f "${project_dir}/requirements.txt" ]] || [[ -f "${project_dir}/pyproject.toml" ]]; then
    language="python"
    if grep -q 'django' "${project_dir}/requirements.txt" 2>/dev/null || \
       grep -q 'django' "${project_dir}/pyproject.toml" 2>/dev/null; then
      framework="django"
    elif grep -q 'fastapi' "${project_dir}/requirements.txt" 2>/dev/null || \
         grep -q 'fastapi' "${project_dir}/pyproject.toml" 2>/dev/null; then
      framework="fastapi"
    elif grep -q 'flask' "${project_dir}/requirements.txt" 2>/dev/null || \
         grep -q 'flask' "${project_dir}/pyproject.toml" 2>/dev/null; then
      framework="flask"
    fi
  elif [[ -f "${project_dir}/Cargo.toml" ]]; then
    language="rust"
  elif [[ -f "${project_dir}/go.mod" ]]; then
    language="go"
  elif [[ -f "${project_dir}/build.gradle" ]] || [[ -f "${project_dir}/pom.xml" ]]; then
    language="java"
  fi

  # Testing framework detection
  if [[ -f "${project_dir}/vitest.config.ts" ]] || [[ -f "${project_dir}/vitest.config.js" ]]; then
    testing="vitest"
  elif [[ -f "${project_dir}/jest.config.js" ]] || [[ -f "${project_dir}/jest.config.ts" ]] || \
       grep -q '"jest"' "${project_dir}/package.json" 2>/dev/null; then
    testing="jest"
  elif [[ -f "${project_dir}/pytest.ini" ]] || \
       { [[ -f "${project_dir}/pyproject.toml" ]] && grep -q '\[tool.pytest\]' "${project_dir}/pyproject.toml" 2>/dev/null; }; then
    testing="pytest"
  fi

  # Linter/formatter detection
  if [[ -f "${project_dir}/biome.json" ]] || [[ -f "${project_dir}/biome.jsonc" ]]; then
    linter="biome"
  elif [[ -f "${project_dir}/.eslintrc" ]] || [[ -f "${project_dir}/.eslintrc.js" ]] || \
       [[ -f "${project_dir}/.eslintrc.json" ]] || [[ -f "${project_dir}/eslint.config.js" ]]; then
    linter="eslint"
  elif [[ -f "${project_dir}/.ruff.toml" ]] || [[ -f "${project_dir}/ruff.toml" ]]; then
    linter="ruff"
  fi

  # Package manager detection
  if [[ -f "${project_dir}/bun.lockb" ]] || [[ -f "${project_dir}/bun.lock" ]]; then
    pkgmgr="bun"
  elif [[ -f "${project_dir}/pnpm-lock.yaml" ]]; then
    pkgmgr="pnpm"
  elif [[ -f "${project_dir}/yarn.lock" ]]; then
    pkgmgr="yarn"
  elif [[ -f "${project_dir}/package-lock.json" ]]; then
    pkgmgr="npm"
  elif [[ -f "${project_dir}/uv.lock" ]]; then
    pkgmgr="uv"
  elif [[ -f "${project_dir}/Pipfile.lock" ]]; then
    pkgmgr="pipenv"
  fi

  # Monorepo detection
  if [[ -f "${project_dir}/lerna.json" ]] || [[ -f "${project_dir}/nx.json" ]] || \
     [[ -f "${project_dir}/turbo.json" ]]; then
    monorepo="true"
  elif grep -q '"workspaces"' "${project_dir}/package.json" 2>/dev/null; then
    monorepo="true"
  fi

  # Git branch type detection
  if command -v git &>/dev/null && git -C "${project_dir}" rev-parse --git-dir &>/dev/null 2>&1; then
    local branch
    branch=$(git -C "${project_dir}" branch --show-current 2>/dev/null || echo "")
    case "$branch" in
      feature/*|feat/*) branch_type="feature" ;;
      fix/*|bugfix/*|hotfix/*) branch_type="fix" ;;
      refactor/*) branch_type="refactor" ;;
      release/*) branch_type="release" ;;
      docs/*) branch_type="docs" ;;
      *) branch_type="" ;;
    esac
  fi

  # Use pipe delimiter to avoid awk collapsing empty fields
  printf '%s|%s|%s|%s|%s|%s|%s' "$language" "$framework" "$testing" "$linter" "$pkgmgr" "$monorepo" "$branch_type"
}
