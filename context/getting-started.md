# Getting Started

This guide explains how to use `web-packages` to install an external JavaScript dependency and expose it as static assets from a Ruby project.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add web-packages
~~~

Your project also needs Node.js and one supported package manager: npm, pnpm, Yarn or Bun. Web Packages delegates dependency resolution and script execution to that package manager.

## Add a JavaScript Dependency

Ruby applications commonly need browser libraries without needing a JavaScript bundler. Declare those libraries as regular production dependencies in `package.json`:

~~~ json
{
  "private": true,
  "packageManager": "pnpm@10",
  "dependencies": {
    "morphdom": "^2.7"
  }
}
~~~

Install the dependencies using the detected package manager:

~~~ bash
$ bundle exec bake web:packages:install
~~~

The package manager remains responsible for its lock file and `node_modules`. Use immutable installation in CI:

~~~ bash
$ bundle exec bake web:packages:install frozen=true
~~~

## Select Browser Files

Packages often contain development sources, tests and metadata that should not be deployed. Add a `web-packages` section which selects the browser-facing files:

~~~ json
{
  "private": true,
  "packageManager": "pnpm@10",
  "dependencies": {
    "morphdom": "^2.7"
  },
  "web-packages": {
    "packages": {
      "morphdom": {
        "include": ["morphdom-esm.js"],
        "imports": {
          "morphdom": "morphdom-esm.js"
        }
      }
    }
  }
}
~~~

Direct production dependencies are selected by default. The package-specific object narrows the copied files and defines an import-map entry.

## Generate Static Packages

Materialize the configured packages:

~~~ bash
$ bundle exec bake web:packages:update
~~~

The default output is `public/_components`. Web Packages builds the complete output in a temporary directory and replaces the existing projection only after every package has been validated.

Print the generated browser import map:

~~~ bash
$ bundle exec bake web:packages:import_map:show
~~~

For the example above, the result includes:

~~~ json
{
  "imports": {
    "morphdom": "/_components/morphdom/morphdom-esm.js"
  }
}
~~~

Your application can embed this JSON in a `<script type="importmap">` element and serve `public/_components` with its other static assets.

## Run JavaScript Tests

Web Packages runs scripts from the root `package.json` without imposing a test framework:

~~~ json
{
  "scripts": {
    "test": "node --test"
  }
}
~~~

~~~ bash
$ bundle exec bake web:packages:test
~~~

Pass another script name when a project has multiple JavaScript test suites:

~~~ bash
$ bundle exec bake web:packages:test script=test:browser
~~~

## Verify Generated Files

Projects which commit or deploy the static projection can verify that it matches the current dependencies and configuration:

~~~ bash
$ bundle exec bake web:packages:check
~~~

See the [Static Packages](../static-packages/index) guide for detailed selection, manifest and import-map configuration. See [Internal Packages](../internal-packages/index) when JavaScript is developed alongside the Ruby code.
