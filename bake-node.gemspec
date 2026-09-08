# frozen_string_literal: true

require_relative "lib/bake/node/version"

Gem::Specification.new do |spec|
	spec.name = "bake-node"
	spec.version = Bake::Node::VERSION
	
	spec.summary = "Integrate Node.js packages into Bake projects."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/bake-node"
	
	spec.metadata = {
		"bug_tracker_uri" => "https://github.com/socketry/bake-node/issues",
		"changelog_uri" => "https://github.com/socketry/bake-node/blob/main/releases.md",
		"documentation_uri" => "https://socketry.github.io/bake-node/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/socketry/bake-node.git",
	}
	
	spec.files = Dir["{bake,guides,lib}/**/*", "*.md", base: __dir__]
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "bake"
end
