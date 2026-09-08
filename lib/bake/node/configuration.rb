# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "pathname"

require_relative "errors"
require_relative "package"

module Bake
	module Node
		class Configuration
			DEFAULT_OUTPUT = "public/_components"
			DEFAULT_BASE = "/_components/"
			
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
			
			def initialize(root, package_json)
				@root = Pathname.new(root).expand_path
				@package_json = package_json
				
				unless @package_json.is_a?(Hash)
					raise ConfigurationError, "package.json must contain an object!"
				end
				
				configuration = @package_json.fetch("bake-node", {})
				
				unless configuration.is_a?(Hash)
					raise ConfigurationError, "bake-node configuration must be an object!"
				end
				
				@package_root = expand_within_root(configuration.fetch("packageRoot", "node_modules"), "packageRoot")
				@output = configuration.fetch("output", DEFAULT_OUTPUT)
				@base = configuration.fetch("base", DEFAULT_BASE)
				@packages = load_packages(configuration["packages"])
				
				unless @base.is_a?(String) && @base.end_with?("/")
					raise ConfigurationError, "bake-node base must be a string ending in '/'!"
				end
				
				output_path
			end
			
			attr :root
			attr :package_json
			attr :package_root
			attr :base
			attr :packages
			
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
					raise ConfigurationError, "bake-node packages must be an array or object!"
				end
				
				configured.sort.to_h do |name, options|
					[name, Package.new(name, options)]
				end
			end
			
			def expand_within_root(path, description, allow_root: true)
				unless path.is_a?(String) && !path.empty?
					raise ConfigurationError, "bake-node #{description} must be a non-empty string!"
				end
				
				expanded = (@root + path).expand_path
				prefix = @root.to_s + File::SEPARATOR
				
				unless expanded.to_s.start_with?(prefix) || (allow_root && expanded == @root)
					raise ConfigurationError, "bake-node #{description} must remain within #{@root}!"
				end
				
				expanded
			end
		end
	end
end
