# API & CLI Design

Standards for designing APIs and command-line interfaces in DevRail-managed projects. These complement the [Coding Practices](coding-practices.md) and [Release & Versioning](release-versioning.md) standards.

## API Versioning

### Strategy

Version APIs explicitly. Consumers must be able to depend on stable behavior within a version:

| Approach | Format | When to Use |
|---|---|---|
| **URL path** (preferred) | `/v1/users`, `/v2/users` | REST APIs, most services |
| **Header-based** | `Accept: application/vnd.myapp.v1+json` | When URL aesthetics matter or proxying is complex |

### Rules

1. **Every public API is versioned from day one.** There is no unversioned API.
2. **Never break existing clients without a version bump.** Adding fields is safe. Removing, renaming, or changing field types requires a new version.
3. **Support at least two concurrent versions** during migration. Document the deprecation timeline.
4. **Version the contract, not the implementation.** Internal refactors do not require a version bump if the external behavior is unchanged.

## Request/Response Format

### Default: JSON

All APIs use JSON for request and response bodies unless there is a specific reason not to (e.g., file uploads, streaming binary data).

### Response Envelope

Use a consistent envelope structure:

```json
{
  "data": { ... },
  "meta": {
    "request_id": "abc-123",
    "timestamp": "2026-02-25T10:00:00Z"
  }
}
```

### Rules

1. **Use `camelCase` for JSON field names** in APIs that serve web clients. Use `snake_case` if the primary consumer is Python or the team convention prefers it. Be consistent within a project.
2. **Include a request ID** in every response for traceability.
3. **Use ISO 8601 for timestamps.** Always include timezone (`Z` or `+00:00`).
4. **Nullable fields are explicit.** If a field can be `null`, document it. If a field is absent, it means "not provided" -- not the same as `null`.

## Error Responses

### Structure

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request body is invalid.",
    "details": [
      {
        "field": "email",
        "issue": "Must be a valid email address."
      }
    ]
  }
}
```

### HTTP Status Codes

Use status codes correctly:

| Code | Meaning | When |
|---|---|---|
| `200` | OK | Successful read or update |
| `201` | Created | Successful resource creation |
| `204` | No Content | Successful deletion, no body returned |
| `400` | Bad Request | Validation error, malformed input |
| `401` | Unauthorized | Missing or invalid authentication |
| `403` | Forbidden | Authenticated but not authorized |
| `404` | Not Found | Resource does not exist |
| `409` | Conflict | Duplicate resource, concurrent modification |
| `422` | Unprocessable Entity | Valid syntax but semantic error |
| `429` | Too Many Requests | Rate limit exceeded |
| `500` | Internal Server Error | Unexpected server failure |

### Rules

1. **Never return `200` with an error body.** Use appropriate 4xx/5xx status codes.
2. **Always include a machine-readable error code.** `code` is for programmatic handling; `message` is for humans.
3. **Validation errors list all issues.** Do not stop at the first invalid field -- return all validation failures at once.
4. **Never expose stack traces or internal details** in error responses. Log them server-side.

## CLI Conventions

### Help and Usage

1. **Every command supports `--help`.** This is non-negotiable.
2. **`--help` output follows standard format:** usage line, description, options with defaults, examples.
3. **Use subcommands for complex CLIs.** `mytool users list`, `mytool users create` -- not `mytool --list-users`.

### Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | General error (runtime failure, operation failed) |
| `2` | Misuse (invalid arguments, missing required flags) |

### Output

| Audience | Format | Flag |
|---|---|---|
| Humans (default) | Tables, colored text, progress bars | (default) |
| Machines | JSON | `--output json` or `--json` |

### Rules

1. **Structured output for machines, readable output for humans.** Support both with a flag.
2. **Write data to stdout, status to stderr.** This allows piping output to other tools.
3. **No interactive prompts in non-TTY mode.** If stdin is not a terminal, fail with a clear error rather than hanging on a prompt.
4. **Support `--quiet` and `--verbose` flags** for controlling output verbosity.

## Backward Compatibility

### Safe Changes (No Version Bump)

- Adding a new optional field to a response
- Adding a new endpoint
- Adding a new optional query parameter
- Relaxing a validation constraint (accepting more inputs)

### Breaking Changes (Require Version Bump)

- Removing or renaming a field
- Changing a field's type
- Adding a new required field to a request
- Changing the semantic meaning of an existing field
- Changing error codes or response structures
- Removing an endpoint
- Tightening a validation constraint (rejecting previously valid inputs)

### Deprecation Process

1. **Mark as deprecated** in documentation and response headers (`Deprecation: true`, `Sunset: <date>`).
2. **Log usage** of deprecated features to track migration progress.
3. **Provide a migration guide** with specific instructions for updating to the new version.
4. **Remove after the documented sunset date** and at least one major version bump.

## Documentation

### APIs

1. **OpenAPI/Swagger specification** is required for all REST APIs. The spec is the source of truth.
2. **Keep the spec in sync with the code.** Generate from code annotations or validate the spec against the implementation in CI.
3. **Include examples** for every endpoint -- request body, response body, error response.
4. **Document authentication requirements** for each endpoint.

### CLIs

1. **`--help` is the primary documentation.** It must be accurate and complete.
2. **README includes common usage examples.** Show the 3-5 most common workflows.
3. **Man pages** are recommended for CLIs distributed via package managers.

## Pagination, Filtering, and Rate Limiting

### Pagination

For endpoints that return collections:

| Parameter | Purpose | Example |
|---|---|---|
| `page` / `offset` | Position in the result set | `?page=2` or `?offset=20` |
| `limit` / `per_page` | Number of items per page | `?limit=50` |

Include pagination metadata in the response:

```json
{
  "data": [ ... ],
  "meta": {
    "page": 2,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

### Filtering and Sorting

- Use query parameters for filtering: `?status=active&role=admin`
- Use a `sort` parameter with field and direction: `?sort=created_at:desc`
- Document all supported filter fields and sort options

### Rate Limiting

1. **Return rate limit headers** on every response:
   - `X-RateLimit-Limit` -- requests allowed per window
   - `X-RateLimit-Remaining` -- requests remaining in current window
   - `X-RateLimit-Reset` -- timestamp when the window resets
2. **Return `429 Too Many Requests`** when the limit is exceeded, with a `Retry-After` header.
3. **Document rate limits** per endpoint or endpoint group.

## Notes

- These standards apply to APIs and CLIs intended for external or cross-team consumption. Internal helper scripts and one-off tools have more flexibility.
- For language-specific API framework conventions (FastAPI, Flask, Express), refer to the relevant language standards.
- API design decisions (field naming convention, pagination style, authentication method) should be recorded in an ADR for the project.
