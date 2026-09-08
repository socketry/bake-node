# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Bake
	module Node
		class Error < StandardError
		end
		
		class ConfigurationError < Error
		end
		
		class PackageError < Error
		end
		
		class CheckError < Error
		end
	end
end
