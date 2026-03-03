---
title: "JavaScript"
linkTitle: "JavaScript"
weight: 35
description: "JavaScript/TypeScript tooling standards: ESLint, Prettier, npm audit, Vitest, and tsc."
---

JavaScript and TypeScript projects use ESLint for linting, Prettier for formatting, npm audit for security scanning, Vitest for testing, and tsc for type checking. A single `javascript` entry in `.devrail.yml` covers both languages.

## Tools

| Category | Tool | Purpose |
|---|---|---|
| Linter | ESLint v9 | JavaScript/TypeScript linter (flat config) |
| Formatter | Prettier | Opinionated code formatter (JS/TS/JSON/CSS/MD) |
| Security | npm audit | Scans `package-lock.json` for known vulnerabilities |
| Tests | Vitest | Fast, ESM-native test runner (Jest-compatible API) |
| Type Check | tsc --noEmit | TypeScript compiler (gated on `tsconfig.json`) |

All tools are pre-installed in the dev-toolchain container. Do not install them on the host.

## Configuration

### ESLint

Config file: `eslint.config.js` (flat config) at repository root.

```js
// eslint.config.js -- DevRail JS/TS lint configuration
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.recommended,
  {
    ignores: ["node_modules/", "dist/", "build/", "coverage/"],
  }
);
```

For JavaScript-only projects (no TypeScript):

```js
// eslint.config.js -- DevRail JS-only lint configuration
import eslint from "@eslint/js";

export default [
  eslint.configs.recommended,
  {
    ignores: ["node_modules/", "dist/", "build/", "coverage/"],
  },
];
```

ESLint v9 uses flat config (`eslint.config.js`), not the legacy `.eslintrc` format. The `@eslint/js` and `typescript-eslint` packages are installed globally in the container so flat config imports resolve without project-local `node_modules`.

### Prettier

Config file: `.prettierrc` at repository root.

```json
{
  "semi": true,
  "singleQuote": false,
  "trailingComma": "es5",
  "printWidth": 80,
  "tabWidth": 2
}
```

A `.prettierignore` file is required to exclude generated files:

```
node_modules/
dist/
build/
coverage/
```

Prettier formats JS, TS, JSON, CSS, and Markdown files. The `.prettierignore` controls scope.

### TypeScript

Config file: `tsconfig.json` at repository root. When present, `tsc --noEmit` runs as part of `make lint`.

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist", "build"]
}
```

### Vitest

Config file: `vitest.config.ts` (or `vitest.config.js`) at repository root.

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    coverage: {
      reporter: ["text", "json", "html"],
    },
  },
});
```

## Makefile Targets

| Target | Command | Description |
|---|---|---|
| `make lint` | `eslint .` | Lint all JS/TS files |
| `make lint` | `tsc --noEmit` | Type check (if `tsconfig.json` exists) |
| `make format` | `prettier --check .` | Check formatting |
| `make security` | `npm audit --audit-level=moderate` | Dependency vulnerability scanning (if `package-lock.json` exists) |
| `make test` | `vitest run` | Run test suite (if `*.test.*` or `*.spec.*` files exist) |

## Pre-Commit Hooks

### Local Hooks (run on every commit, under 30 seconds)

ESLint and Prettier run on every commit to catch lint and formatting issues:

```yaml
# .pre-commit-config.yaml -- JavaScript/TypeScript hooks
repos:
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v9.27.0
    hooks:
      - id: eslint
        additional_dependencies:
          - eslint
          - "@eslint/js"
          - typescript-eslint
          - typescript

  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v4.0.0-alpha.8
    hooks:
      - id: prettier
```

### CI-Only (too slow for local hooks)

- `npm audit --audit-level=moderate` -- dependency vulnerability scanning
- `vitest run` -- full test suite

## Notes

- **Single `javascript` entry covers both JS and TS.** Do not add a separate `typescript` entry to `.devrail.yml`. TypeScript support auto-activates when `tsconfig.json` is present.
- **ESLint v9 uses flat config.** The config file is `eslint.config.js` (not `.eslintrc`). The `@eslint/js` and `typescript-eslint` packages provide rule configurations for the flat config format.
- **tsc runs under `make lint`, not a separate target.** Type checking is static analysis (like mypy for Python). It is gated on `tsconfig.json` presence.
- **Prettier formats more than JS/TS.** Prettier handles JSON, CSS, Markdown, and other file types. Projects must use `.prettierignore` to exclude generated files.
- **npm audit gates on `package-lock.json`.** If no `package-lock.json` exists, npm audit is skipped because there are no locked dependencies to scan.
- **Vitest gates on test file presence.** If no `*.test.*` or `*.spec.*` files exist, vitest is skipped.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting coding practices and git workflow standards that apply to all languages, see [Coding Practices](/docs/standards/practices/).
