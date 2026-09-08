# Static Packages

This guide explains how to control which installed package files are deployed, generate browser import maps and verify the resulting static projection.

## Package Selection

All direct `dependencies` from the root `package.json` are selected by default. Use `bake-node.packages` to refine that selection:

~~~ json
{
  "dependencies": {
    "morphdom": "^2.7",
    "server-only-package": "^1.0"
  },
  "bake-node": {
    "packages": {
      "morphdom": {
        "include": ["morphdom-esm.js"]
      },
      "server-only-package": false,
      "@example/internal": true
    }
  }
}
~~~

Set a dependency to `false` to exclude it. Use `true` or an empty object to accept the default behavior. Additional workspace packages can be listed even when they are not direct dependencies.

## Source Directories

Many packages publish browser-ready files in `dist/`. Bake Node uses `dist` automatically when that directory exists and otherwise uses the package root.

Override the source when a package has another layout:

~~~ json
{
  "bake-node": {
    "packages": {
      "example": {
        "source": "browser"
      }
    }
  }
}
~~~

Set `source` to `.` when the package root should be used even though a `dist/` directory exists.

## Selecting a Subset of Files

npm packages frequently contain far more than an application needs at runtime. `include` accepts package-source-relative glob patterns:

~~~ json
{
  "bake-node": {
    "packages": {
      "mermaid": {
        "source": "dist",
        "include": [
          "mermaid.esm.min.mjs",
          "chunks/mermaid.esm.min/**/*.mjs"
        ]
      }
    }
  }
}
~~~

When `include` is omitted, the complete source directory is copied except for nested `.git` and `node_modules` directories. Absolute paths and parent traversal are rejected, and symbolic links cannot escape the installed package.

## Import Maps

Map browser import specifiers to selected package files:

~~~ json
{
  "bake-node": {
    "base": "/_components/",
    "packages": {
      "mermaid": {
        "source": "dist",
        "include": ["mermaid.esm.min.mjs"],
        "imports": {
          "mermaid": "mermaid.esm.min.mjs"
        }
      }
    }
  }
}
~~~

Relative import targets must refer to files included in the static projection. Absolute paths and URLs are preserved, which allows a project to combine local files and CDN imports explicitly. Duplicate specifiers are rejected.

Generate and inspect the import map with:

~~~ bash
$ bundle exec bake node:packages:static
$ bundle exec bake node:importmap:show
~~~

## Output and Manifest

The default output directory and public URL prefix are configurable:

~~~ json
{
  "bake-node": {
    "output": "public/_components",
    "base": "/_components/",
    "packageRoot": "node_modules"
  }
}
~~~

Static installation writes `.manifest.json` inside the output directory. This hidden file describes the generated projection independently of the tool which created it. The deterministic manifest records:

- Package versions and selected source directories.
- Every installed file and its SHA-256 digest.
- Import-map entries.
- A digest of the complete manifest.

The manifest can be loaded once by an application or used as a cache key without repeatedly scanning the package tree.

## Keeping Output Current

The entire output tree is staged and swapped atomically. A missing file, invalid import, unsafe symbolic link or malformed package prevents replacement of the last working output.

Use the check task in deployment or CI when generated files are expected to be current:

~~~ bash
$ bundle exec bake node:packages:check
~~~

The check rebuilds the desired manifest in a temporary directory and verifies both the manifest and current file contents.
