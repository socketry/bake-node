# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "pathname"

require_relative "errors"

module Bake
	module Node
		class Package
			NAME_PATTERN = /\A(?:@[a-z0-9._-]+\/)?[a-z0-9._-]+\z/i
			
			def initialize(name, options = {})
				unless name.is_a?(String) && NAME_PATTERN.match?(name)
					raise ConfigurationError, "Invalid package name: #{name.inspect}!"
				end
				
				unless options.is_a?(Hash)
					raise ConfigurationError, "Configuration for #{name} must be an object!"
				end
				
				@name = name
				@source = options["source"]
				@include_patterns = options["include"]
				@imports = options.fetch("imports", {})
				
				validate
			end
			
			attr :name
			attr :source
			attr :include_patterns
			attr :imports
			
			private
			
			def validate
				validate_relative_path(@source, "source") if @source
				
				if @include_patterns
					unless @include_patterns.is_a?(Array) && @include_patterns.any?
						raise ConfigurationError, "The include patterns for #{@name} must be a non-empty array!"
					end
					
					@include_patterns.each do |pattern|
						validate_relative_path(pattern, "include pattern")
					end
				end
				
				unless @imports.is_a?(Hash) && @imports.all?{|key, value| key.is_a?(String) && value.is_a?(String)}
					raise ConfigurationError, "The imports for #{@name} must map strings to strings!"
				end
			end
			
			def validate_relative_path(path, description)
				unless path.is_a?(String) && !path.empty?
					raise ConfigurationError, "The #{description} for #{@name} must be a non-empty string!"
				end
				
				pathname = Pathname.new(path)
				
				if pathname.absolute? || pathname.each_filename.any?{|component| component == ".."}
					raise ConfigurationError, "The #{description} for #{@name} must remain within the package: #{path.inspect}!"
				end
			end
		end
	end
end
