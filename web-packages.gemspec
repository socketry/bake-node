# frozen_string_literal: true

require_relative "lib/web/packages/version"

Gem::Specification.new do |spec|
	spec.name = "web-packages"
	spec.version = Web::Packages::VERSION
	
	spec.summary = "Integrate JavaScript packages into Ruby web applications."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/web-packages"
	
	spec.metadata = {
		"bug_tracker_uri" => "https://github.com/socketry/web-packages/issues",
		"changelog_uri" => "https://github.com/socketry/web-packages/blob/main/releases.md",
		"documentation_uri" => "https://socketry.github.io/web-packages/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/socketry/web-packages.git",
	}
	
	spec.files = Dir["{bake,guides,lib}/**/*", "*.md", base: __dir__]
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "bake"
end
