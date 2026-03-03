# JavaScript/TypeScript Standards

A single `javascript` entry in `.devrail.yml` covers both JavaScript and TypeScript. TypeScript type checking (`tsc --noEmit`) auto-activates when `tsconfig.json` is present.

## Tools

| Concern | Tool | Version Strategy |
|---|---|---|
| Linter | ESLint v9 | Latest in container |
| Formatter | Prettier | Latest in container |
| Security | npm audit | Built into npm |
| Tests | Vitest | Latest in container |
| Type Check | tsc --noEmit | Gated on `tsconfig.json` |

ESLint v9 uses flat config (`eslint.config.js`). TypeScript support is provided by the `typescript-eslint` package.

## Configuration

### ESLint

Config file: `eslint.config.js` (flat config) at repository root.

Recommended `eslint.config.js` for TypeScript projects:

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

### Prettier

Config file: `.prettierrc` at repository root.

Recommended `.prettierrc`:

```json
{
  "semi": true,
  "singleQuote": false,
  "trailingComma": "es5",
  "printWidth": 80,
  "tabWidth": 2
}
```

A `.prettierignore` file is required to prevent Prettier from formatting generated files:

```
node_modules/
dist/
build/
coverage/
```

Prettier formats JS, TS, JSON, CSS, and Markdown files. The `.prettierignore` file controls scope.

### TypeScript

Config file: `tsconfig.json` at repository root. When present, `tsc --noEmit` runs as part of `make lint`.

Recommended `tsconfig.json`:

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

Recommended `vitest.config.ts`:

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
| `_lint` | `eslint .` | Lint all JS/TS files (if JS/TS files exist) |
| `_lint` | `tsc --noEmit` | Type check (if `tsconfig.json` exists) |
| `_format` | `prettier --check .` | Check formatting (if JS/TS files exist) |
| `_format` (fix) | `prettier --write .` | Apply formatting fixes |
| `_security` | `npm audit --audit-level=moderate` | Dependency vulnerability scanning (if `package-lock.json` exists) |
| `_test` | `vitest run` | Run test suite (if `*.test.*` or `*.spec.*` files exist) |

See [DEVELOPMENT.md](../DEVELOPMENT.md) for the full Makefile contract and two-layer delegation pattern.

## Pre-Commit Hooks

### Local Hooks (< 30 seconds)

ESLint and Prettier run on every commit to catch lint and formatting issues:

```yaml
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

### CI-Only

These run via `make security` and `make test` in CI pipelines. They are **not** configured as pre-commit hooks due to execution time:

- `npm audit --audit-level=moderate` -- dependency vulnerability scanning
- `vitest run` -- full test suite

## Notes

- **Single `javascript` entry covers both JS and TS.** Do not add a separate `typescript` entry to `.devrail.yml`. TypeScript support auto-activates when `tsconfig.json` is present.
- **ESLint v9 uses flat config.** The config file is `eslint.config.js` (not `.eslintrc`). The `@eslint/js` and `typescript-eslint` packages provide rule configurations for the flat config format.
- **tsc runs under `_lint`, not a separate target.** Type checking is static analysis (like mypy for Python). It is gated on `tsconfig.json` presence.
- **Prettier formats more than JS/TS.** Prettier handles JSON, CSS, Markdown, and other file types. Projects must use `.prettierignore` to exclude generated files.
- **npm audit gates on `package-lock.json`.** If no `package-lock.json` exists, npm audit is skipped because there are no locked dependencies to scan.
- **Vitest gates on test file presence.** If no `*.test.*` or `*.spec.*` files exist, vitest is skipped.
- **All tools are pre-installed in the dev-toolchain container.** Do not install them on the host.
- For cross-cutting practices (DRY, idempotency, error handling, testing, naming) and git workflow (branching, code review, conventional commits), see [Coding Practices](coding-practices.md) and [Git Workflow](git-workflow.md).
