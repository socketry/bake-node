# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

def initialize(context)
	super
	
	require "bake/node/controller"
end

# Install packages using the configured package manager.
# @parameter root [String] The directory containing package.json.
# @parameter frozen [Boolean] Require the lock file to remain unchanged.
def install(root: context.root, frozen: false)
	Bake::Node::Controller.new(root).install(frozen: frozen)
end

# Run a package script using the configured package manager.
# @parameter script [String] The package script to run.
# @parameter root [String] The directory containing package.json.
def test(script: "test", root: context.root)
	Bake::Node::Controller.new(root).run(script)
end
