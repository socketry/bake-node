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
		class Controller
			def initialize(root)
				@configuration = Configuration.load(root)
			end
			
			attr :configuration
			
			def install(frozen: false)
				package_manager.install(frozen: frozen)
			end
			
			def run(script)
				package_manager.run(script)
			end
			
			def static(output: nil)
				Static.new(@configuration, output: output).update
			end
			
			def check(output: nil)
				Static.new(@configuration, output: output).check!
			end
			
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
