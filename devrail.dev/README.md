# devrail.dev

> DevRail `v1` is stable. See [STABILITY.md](STABILITY.md) for component status.

The documentation site for [DevRail](https://devrail.dev) -- opinionated development standards for teams that ship with AI agents.

## Quick Start

1. Install [Hugo extended](https://gohugo.io/installation/) and [Go](https://go.dev/dl/)
2. Clone this repository
3. Start the development server:

```bash
make serve
```

## Usage

```bash
make help
```

Available targets:

| Target | Description |
|---|---|
| `make build` | Build the Hugo site |
| `make serve` | Start local Hugo development server |
| `make check` | Run all checks (lint, format, test, security, docs) |
| `make install-hooks` | Install pre-commit hooks |

## Configuration

This site uses Hugo with the [Docsy](https://www.docsy.dev/) theme via Go modules. Configuration is in `hugo.toml`.

## Contributing

See [DEVELOPMENT.md](DEVELOPMENT.md) for development standards and contribution guidelines.

To add a new language ecosystem to DevRail, see the [Contributing to DevRail](../standards/contributing.md) guide.

## License

[MIT](LICENSE)
