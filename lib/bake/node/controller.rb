# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"

require_relative "configuration"
require_relative "manifest"
require_relative "package_manager"
require_relative "static"

module Bake
	module Node
		# Coordinates package-manager commands and static package deployment for a project.
		class Controller
			# Initialize a controller for a project.
			# @parameter root [String | Pathname] The project directory containing `package.json`.
			# @raises [ConfigurationError] If the project configuration is invalid.
			def initialize(root)
				@configuration = Configuration.load(root)
			end
			
			# @attribute [Configuration] The validated project configuration.
			attr :configuration
			
			# Install Node.js packages using the detected package manager.
			# @parameter frozen [Boolean] Whether the lock file must remain unchanged.
			# @raises [Error] If the package-manager command fails.
			def install(frozen: false)
				package_manager.install(frozen: frozen)
			end
			
			# Run a script from the root `package.json` file.
			# @parameter script [String] The script name to run.
			# @raises [Error] If the package-manager command fails.
			def run(script)
				package_manager.run(script)
			end
			
			# Materialize the configured packages as static files.
			# @parameter output [String | Nil] An optional project-relative output directory.
			# @returns [Manifest] The generated static package manifest.
			def static(output: nil)
				Static.new(@configuration, output: output).update
			end
			
			# Verify that the static package projection is current.
			# @parameter output [String | Nil] An optional project-relative output directory.
			# @returns [Boolean] `true` when the static package projection is current.
			# @raises [CheckError] If the static package projection is missing or out of date.
			def check(output: nil)
				Static.new(@configuration, output: output).check!
			end
			
			# Generate an import map from the static package manifest.
			# @parameter output [String | Nil] An optional project-relative output directory.
			# @returns [String] The formatted import map JSON.
			# @raises [CheckError] If the static package manifest is missing or invalid.
			def import_map(output: nil)
				root = @configuration.output_path(output)
				JSON.pretty_generate(Manifest.load(root).import_map)
			end
			
			private
			
			def package_manager
				@package_manager ||= PackageManager.detect(@configuration)
			end
		end
	end
end
