# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Web
	module Packages
		# The base class for Web Packages failures.
		class Error < StandardError
		end
		
		# Raised when project or package configuration is invalid.
		class ConfigurationError < Error
		end
		
		# Raised when an installed package cannot be materialized safely.
		class PackageError < Error
		end
		
		# Raised when generated static packages are missing or out of date.
		class CheckError < Error
		end
	end
end
