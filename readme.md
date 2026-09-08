# Bake Node

Bake Node integrates Node.js packages into Ruby projects using [Bake](https://github.com/ioquatix/bake). It delegates package installation and scripts to the project's chosen package manager, then materializes selected packages as deterministic static assets.

## Motivation

Ruby web projects commonly need two kinds of JavaScript:

- External packages installed from an npm-compatible registry.
- Internal JavaScript packages developed alongside the Ruby code.

Bake Node treats both identically after installation. Package managers project registry dependencies and local workspace packages into `node_modules`; Bake Node reads that installed view and creates a static deployment tree.

## Conventions

The recommended project layout is:

```text
components/                 # Authored internal JavaScript packages.
node_modules/               # Disposable package-manager projection.
public/_components/         # Generated static deployment projection.
package.json                # Workspace, dependencies and Bake Node configuration.
```

Internal packages should contain their own `package.json`. Their directory names do not need to match their package names:

```text
components/
  live/
    package.json            # "name": "@socketry/live"
    Live.js
    test/
```

The root project can expose internal packages through npm-compatible workspaces:

```json
{
  "private": true,
  "workspaces": ["components/*"]
}
```

The `components` directory is a convention, not a requirement. Workspace and local packages can be stored anywhere supported by the selected package manager.

## Configuration

Direct `dependencies` are materialized by default. The optional `bake-node` object configures the output and individual packages:

```json
{
  "packageManager": "pnpm@10",
  "dependencies": {
    "@socketry/live": "^0.17.0",
    "morphdom": "^2.7"
  },
  "bake-node": {
    "output": "public/_components",
    "base": "/_components/",
    "packages": {
      "@socketry/live": {
        "include": ["Live.js"],
        "imports": {"live": "Live.js"}
      },
      "morphdom": {
        "include": ["morphdom-esm.js"],
        "imports": {"morphdom": "morphdom-esm.js"}
      },
      "mermaid": {
        "source": "dist",
        "include": [
          "mermaid.esm.min.mjs",
          "chunks/mermaid.esm.min/**/*.mjs"
        ],
        "imports": {"mermaid": "mermaid.esm.min.mjs"}
      }
    }
  }
}
```

Package overrides are merged with direct dependencies. Set a dependency to `false` to exclude it. Additional workspace packages can be added even when they are not direct dependencies.

The `source` and `include` paths are relative to the installed package and cannot escape it. When `source` is omitted, `dist` is used when present and the package root otherwise. Set `source` to `.` to explicitly select the package root. When `include` is omitted, the complete source directory is copied except for nested `.git` and `node_modules` directories.

## Tasks

Install packages using the detected package manager:

```bash
$ bundle exec bake node:install
```

Use `frozen=true` to select the package manager's immutable installation mode:

```bash
$ bundle exec bake node:install frozen=true
```

Run the configured JavaScript tests:

```bash
$ bundle exec bake node:test
```

Materialize static packages:

```bash
$ bundle exec bake node:packages:static
```

Verify that committed static packages are current:

```bash
$ bundle exec bake node:packages:check
```

Print the generated import map:

```bash
$ bundle exec bake node:importmap:show
```

## Package Manager Selection

The package manager is selected in this order:

1. The `NODE_PACKAGE_MANAGER` environment variable.
2. The standard `packageManager` field in `package.json`.
3. A single recognized lock file.
4. `npm` as the fallback.

Supported package managers are npm, pnpm, Yarn and Bun. Multiple conflicting lock files are rejected rather than selecting one implicitly.

## Static Manifest

Static installation writes `public/_components/.bake-node.json`. The deterministic manifest records package versions, installed files, content hashes and import-map entries. Applications can load the manifest once at startup instead of scanning the filesystem for every request.

The complete output directory is replaced only after every package has been validated and copied successfully. Removed packages and files therefore do not remain in the generated tree, while failures preserve the previous working output.

## Releases

There are no documented releases.

## Contributing

We welcome contributions to this project.

1. Fork it.
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create a new pull request.

## See Also

- [Bake](https://github.com/ioquatix/bake) — Ruby task execution.
- [Utopia](https://github.com/socketry/utopia) — The original static component installer.

## License

Released under the MIT License.

Copyright, 2026, by Samuel Williams.
