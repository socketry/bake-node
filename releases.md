# Releases

## Unreleased

### Projection Manifest

The generated static projection manifest is now named `.manifest.json`, reflecting that it describes the output directory rather than exposing Bake Node as part of the artifact's interface. Existing projections should be regenerated with `bake node:packages:static`; package checks will treat the previous `.bake-node.json` output as stale.

## v0.0.1

### Added

  - Add package-manager orchestration and static Node.js package materialization.
  - Add deterministic manifests and import maps.
