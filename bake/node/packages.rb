# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

def initialize(context)
	super
	
	require "bake/node/controller"
end

# Materialize configured Node.js packages as static files.
# @parameter root [String] The directory containing package.json.
# @parameter output [String | Nil] Override the configured output directory.
def static(root: context.root, output: nil)
	Bake::Node::Controller.new(root).static(output: output)
end

# Check that the materialized static packages are current.
# @parameter root [String] The directory containing package.json.
# @parameter output [String | Nil] Override the configured output directory.
def check(root: context.root, output: nil)
	Bake::Node::Controller.new(root).check(output: output)
end
