# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "pathname"

require_relative "errors"
require_relative "package"

module Web
	module Packages
		# Loads and validates Web Packages settings from a project's `package.json` file.
		class Configuration
			DEFAULT_OUTPUT = "public/_components"
			DEFAULT_BASE = "/_components/"
			
			# Load the configuration for a project.
			# @parameter root [String | Pathname] The project directory containing `package.json`.
			# @returns [Configuration] The validated project configuration.
			# @raises [ConfigurationError] If `package.json` is missing, malformed or invalid.
			def self.load(root)
				root = Pathname.new(root).expand_path
				package_path = root + "package.json"
				
				unless package_path.file?
					raise ConfigurationError, "Could not find package.json in #{root}!"
				end
				
				package_json = JSON.parse(package_path.read)
				new(root, package_json)
			rescue JSON::ParserError => error
				raise ConfigurationError, "Could not parse #{package_path}: #{error.message}"
			end
			
			# Initialize a configuration from parsed package metadata.
			# @parameter root [String | Pathname] The project root directory.
			# @parameter package_json [Hash] The parsed contents of `package.json`.
			# @raises [ConfigurationError] If the configuration is invalid.
			def initialize(root, package_json)
				@root = Pathname.new(root).expand_path
				@package_json = package_json
				
				unless @package_json.is_a?(Hash)
					raise ConfigurationError, "package.json must contain an object!"
				end
				
				configuration = @package_json.fetch("web-packages", {})
				
				unless configuration.is_a?(Hash)
					raise ConfigurationError, "web-packages configuration must be an object!"
				end
				
				@package_root = expand_within_root(configuration.fetch("packageRoot", "node_modules"), "packageRoot")
				@output = configuration.fetch("output", DEFAULT_OUTPUT)
				@base = configuration.fetch("base", DEFAULT_BASE)
				@packages = load_packages(configuration["packages"])
				
				unless @base.is_a?(String) && @base.end_with?("/")
					raise ConfigurationError, "web-packages base must be a string ending in '/'!"
				end
				
				output_path
			end
			
			# @attribute [Pathname] The expanded project root directory.
			attr :root
			
			# @attribute [Hash] The parsed contents of `package.json`.
			attr :package_json
			
			# @attribute [Pathname] The directory containing installed Node.js packages.
			attr :package_root
			
			# @attribute [String] The public URL prefix for static packages.
			attr :base
			
			# @attribute [Hash(String, Package)] The packages selected for static deployment.
			attr :packages
			
			# Resolve the configured output directory.
			# @parameter override [String | Nil] An optional project-relative output directory.
			# @returns [Pathname] The expanded output directory.
			# @raises [ConfigurationError] If the output directory escapes the project root.
			def output_path(override = nil)
				expand_within_root(override || @output, "output", allow_root: false)
			end
			
			private
			
			def load_packages(overrides)
				configured = {}
				
				dependencies = @package_json.fetch("dependencies", {})
				unless dependencies.is_a?(Hash)
					raise ConfigurationError, "package.json dependencies must be an object!"
				end
				
				dependencies.each_key do |name|
					configured[name] = {}
				end
				
				case overrides
				when nil
					# All direct dependencies use their defaults.
				when Array
					configured = overrides.to_h{|name| [name, {}]}
				when Hash
					overrides.each do |name, options|
						if options == false
							configured.delete(name)
						else
							configured[name] = options == true ? {} : options
						end
					end
				else
					raise ConfigurationError, "web-packages packages must be an array or object!"
				end
				
				configured.sort.to_h do |name, options|
					[name, Package.new(name, options)]
				end
			end
			
			def expand_within_root(path, description, allow_root: true)
				unless path.is_a?(String) && !path.empty?
					raise ConfigurationError, "web-packages #{description} must be a non-empty string!"
				end
				
				expanded = (@root + path).expand_path
				prefix = @root.to_s + File::SEPARATOR
				
				unless expanded.to_s.start_with?(prefix) || (allow_root && expanded == @root)
					raise ConfigurationError, "web-packages #{description} must remain within #{@root}!"
				end
				
				expanded
			end
		end
	end
end
