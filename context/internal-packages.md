# Internal Packages

This guide explains how to organize JavaScript developed inside a Ruby project as independent workspace packages while using Bake Node for testing and static deployment.

## Why Use Workspace Packages?

Internal JavaScript often has its own module boundaries, tests and release concerns. Mixing it into the Ruby `lib/` hierarchy makes both languages harder to navigate, while placing authored code directly in `node_modules` makes it disposable.

Bake Node recommends three distinct layers:

~~~ text
components/                 # Authored internal JavaScript packages.
node_modules/               # Disposable package-manager projection.
public/_components/         # Generated static deployment projection.
package.json                # Workspace and Bake Node configuration.
~~~

`components/` describes the role of the code without requiring a second language-level hierarchy. A single directory can contain one or many packages.

## Create an Internal Package

Give each internal library its own `package.json` and tests:

~~~ text
components/
  live/
    package.json
    Live.js
    test/
      Live.js
~~~

For example:

~~~ json
{
  "name": "@example/live",
  "private": true,
  "type": "module",
  "exports": "./Live.js",
  "scripts": {
    "test": "node --test"
  }
}
~~~

The directory name and package name do not need to match. Package identity comes from the internal `package.json`.

## Add the Workspace

Expose internal packages through the root workspace configuration:

~~~ json
{
  "private": true,
  "workspaces": ["components/*"],
  "bake-node": {
    "packages": {
      "@example/live": {
        "include": ["Live.js"],
        "imports": {
          "live": "Live.js"
        }
      }
    }
  }
}
~~~

The package manager projects the workspace package into `node_modules/@example/live`, usually using a link. Bake Node resolves that link, ensures selected files remain inside the package, and copies the resulting files into `public/_components/@example/live`.

The `components/` path is a convention rather than a requirement. Any workspace or local-package layout supported by the selected package manager can be used.

## Test Internal Packages

Each package can keep its own test command. Define a root script which invokes the workspace tests according to the selected package manager, then let Bake Node run that script:

~~~ json
{
  "scripts": {
    "test": "npm test --workspaces --if-present"
  }
}
~~~

~~~ bash
$ bundle exec bake node:test
~~~

pnpm, Yarn and Bun have their own workspace script syntax. Bake Node deliberately does not abstract those differences; the root script remains the project's explicit test entry point.

## Multiple Internal Libraries

No additional multiplexing layer is needed. Add more package directories beneath `components/`, include them in the workspace pattern, and select the packages which should be deployed:

~~~ text
components/
  editor/
    package.json
  live/
    package.json
  syntax/
    package.json
~~~

Packages used only for development do not need to appear in `bake-node.packages`. Packages listed there can be deployed even when they are not direct root dependencies.

## Avoid Authoring in `node_modules`

`node_modules` is owned by the package manager and can be replaced by any installation command. Keep authored packages in `components/` and treat both `node_modules/` and `public/_components/` as projections which can be rebuilt from source and lock files.
