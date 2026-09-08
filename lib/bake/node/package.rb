# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "pathname"

require_relative "errors"

module Bake
	module Node
		# Describes how one installed Node.js package is exposed as static files.
		class Package
			NAME_PATTERN = /\A(?:@[a-z0-9._-]+\/)?[a-z0-9._-]+\z/i
			
			# Initialize a package selection.
			# @parameter name [String] The npm package name, including an optional scope.
			# @parameter options [Hash] The package's source, include patterns and import mappings.
			# @raises [ConfigurationError] If the package name or options are invalid.
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
			
			# @attribute [String] The npm package name.
			attr :name
			
			# @attribute [String | Nil] The configured package-relative source directory.
			attr :source
			
			# @attribute [Array(String) | Nil] The package-relative file patterns to include.
			attr :include_patterns
			
			# @attribute [Hash(String, String)] The import specifiers exposed by the package.
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
