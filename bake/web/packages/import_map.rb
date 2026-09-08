# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

def initialize(context)
	super
	
	require "web/packages/controller"
end

# Print the import map for the materialized static packages.
# @parameter root [String] The directory containing package.json.
# @parameter output [String | Nil] Override the configured output directory.
def show(root: context.root, output: nil)
	puts Web::Packages::Controller.new(root).import_map(output: output)
end
