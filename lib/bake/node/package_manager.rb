# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "errors"

module Bake
	module Node
		class PackageManager
			LOCK_FILES = {
				"package-lock.json" => "npm",
				"npm-shrinkwrap.json" => "npm",
				"pnpm-lock.yaml" => "pnpm",
				"yarn.lock" => "yarn",
				"bun.lock" => "bun",
				"bun.lockb" => "bun",
			}.freeze
			
			SUPPORTED = ["npm", "pnpm", "yarn", "bun"].freeze
			
			def self.detect(configuration, environment: ENV)
				if name = environment["NODE_PACKAGE_MANAGER"]
					return new(configuration.root, name)
				end
				
				if declaration = configuration.package_json["packageManager"]
					unless declaration.is_a?(String)
						raise ConfigurationError, "packageManager must be a string!"
					end
					
					return new(configuration.root, declaration.split("@", 2).first)
				end
				
				managers = LOCK_FILES.filter_map do |path, manager|
					manager if (configuration.root + path).file?
				end.uniq
				
				if managers.size > 1
					raise ConfigurationError, "Multiple package manager lock files were found: #{managers.join(', ')}!"
				end
				
				new(configuration.root, managers.first || "npm")
			end
			
			def initialize(root, name)
				unless SUPPORTED.include?(name)
					raise ConfigurationError, "Unsupported package manager: #{name.inspect}!"
				end
				
				@root = root
				@name = name
			end
			
			attr :root
			attr :name
			
			def install(frozen: false)
				execute(install_command(frozen: frozen))
			end
			
			def run(script)
				unless script.is_a?(String) && !script.empty?
					raise ArgumentError, "Script must be a non-empty string!"
				end
				
				execute([@name, "run", script])
			end
			
			def install_command(frozen: false)
				command = case @name
				when "npm"
					frozen ? ["npm", "ci"] : ["npm", "install"]
				when "pnpm"
					["pnpm", "install"]
				when "yarn"
					["yarn", "install"]
				when "bun"
					["bun", "install"]
				end
				
				if frozen && @name != "npm"
					command << (@name == "yarn" ? "--immutable" : "--frozen-lockfile")
				end
				
				command
			end
			
			private
			
			def execute(command)
				unless system(*command, chdir: @root.to_s)
					raise Error, "Command failed: #{command.join(' ')}"
				end
			end
		end
	end
end
