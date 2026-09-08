# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

def initialize(context)
	super
	
	require "web/packages/controller"
end

# Install packages using the configured package manager.
# @parameter root [String] The directory containing package.json.
# @parameter frozen [Boolean] Require the lock file to remain unchanged.
def install(root: context.root, frozen: false)
	Web::Packages::Controller.new(root).install(frozen: frozen)
end

# Run a package script using the configured package manager.
# @parameter script [String] The package script to run.
# @parameter root [String] The directory containing package.json.
def test(script: "test", root: context.root)
	Web::Packages::Controller.new(root).run(script)
end

# Materialize configured web packages as static files.
# @parameter root [String] The directory containing package.json.
# @parameter output [String | Nil] Override the configured output directory.
def update(root: context.root, output: nil)
	Web::Packages::Controller.new(root).update(output: output)
end

# Check that the materialized web packages are current.
# @parameter root [String] The directory containing package.json.
# @parameter output [String | Nil] Override the configured output directory.
def check(root: context.root, output: nil)
	Web::Packages::Controller.new(root).check(output: output)
end
