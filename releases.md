# Releases

## Unreleased

### Web Packages

The gem has been renamed from `bake-node` to `web-packages` to describe its role in exposing JavaScript packages to web applications rather than the tools used to install them. Replace the `bake-node` dependency with `web-packages`, change `bake/node` require paths to `web/packages`, and replace the `Bake::Node` namespace with `Web::Packages`.

Configuration in `package.json` now uses the `web-packages` key. Bake tasks now use the `web:packages` namespace: installation and scripts are available through `web:packages:install` and `web:packages:test`, while static projections are managed through `web:packages:update` and `web:packages:check`. The import map can be inspected with `web:packages:import_map:show`.

`Bake::Node::Static` has become `Web::Packages::Projection`, and `Bake::Node::Controller#static` has become `Web::Packages::Controller#update`. The `.manifest.json` projection format is unchanged, so existing generated projections remain compatible.

## v0.1.0

### Projection Manifest

The generated static projection manifest is now named `.manifest.json`, reflecting that it describes the output directory rather than exposing Bake Node as part of the artifact's interface. Existing projections should be regenerated with `bake node:packages:static`; package checks will treat the previous `.bake-node.json` output as stale.

## v0.0.1

### Added

  - Add package-manager orchestration and static Node.js package materialization.
  - Add deterministic manifests and import maps.
