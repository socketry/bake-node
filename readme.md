# Web Packages

Web Packages integrates Node.js packages into Ruby projects using [Bake](https://github.com/ioquatix/bake). It delegates installation and scripts to npm-compatible package managers, then materializes selected packages as deterministic static assets.

[![Development Status](https://github.com/socketry/web-packages/workflows/Test/badge.svg)](https://github.com/socketry/web-packages/actions?workflow=Test)

## Features

  - Supports npm, pnpm, Yarn and Bun without replacing their package-management behavior.
  - Treats registry dependencies and local workspace packages consistently through `node_modules`.
  - Copies complete distributions or carefully selected files into `public/_components`.
  - Generates a deterministic manifest and browser import map.
  - Provides Bake tasks for installation, scripts, static deployment and verification.

## Usage

Please see the [project documentation](https://socketry.github.io/web-packages/) for more details.

  - [Getting Started](https://socketry.github.io/web-packages/guides/getting-started/index) - This guide explains how to use `web-packages` to install an external JavaScript dependency and expose it as static assets from a Ruby project.

  - [Internal Packages](https://socketry.github.io/web-packages/guides/internal-packages/index) - This guide explains how to organize JavaScript developed inside a Ruby project as independent workspace packages while using Web Packages for testing and static deployment.

  - [Static Packages](https://socketry.github.io/web-packages/guides/static-packages/index) - This guide explains how to control which installed package files are deployed, generate browser import maps and verify the resulting static projection.

## Releases

Please see the [project releases](https://socketry.github.io/web-packages/releases/index) for all releases.

### v0.2.0

  - [Web Packages](https://socketry.github.io/web-packages/releases/index#web-packages)

### v0.1.0

  - [Projection Manifest](https://socketry.github.io/web-packages/releases/index#projection-manifest)

### v0.0.1

  - [Added](https://socketry.github.io/web-packages/releases/index#added)

## Contributing

We welcome contributions to this project.

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature.'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create a new pull request.

### Running Tests

To run the test suite:

``` bash
$ bundle exec bake test
```

### Making Releases

To make a new release:

``` bash
$ bundle exec bake gem:release:patch # or minor or major
```

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.

## See Also

  - [Bake](https://github.com/ioquatix/bake) — Ruby task execution.
  - [Utopia](https://github.com/socketry/utopia) — The original static component installer.
