# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "digest"
require "json"
require "pathname"

require_relative "errors"

module Bake
	module Node
		# Records the content and import mappings of a static package projection.
		class Manifest
			FILENAME = ".manifest.json"
			
			# Build a deterministic manifest.
			# @parameter base [String] The public URL prefix for static packages.
			# @parameter imports [Hash(String, String)] The import-map entries.
			# @parameter packages [Hash(String, Hash)] The installed package metadata.
			# @returns [Manifest] The generated manifest.
			def self.build(base:, imports:, packages:)
				data = {
					"format" => 1,
					"base" => base,
					"imports" => imports.sort.to_h,
					"packages" => packages.sort.to_h,
				}
				
				data["digest"] = Digest::SHA256.hexdigest(JSON.generate(data))
				new(data)
			end
			
			# Load a manifest from a static output directory.
			# @parameter root [String | Pathname] The static output directory.
			# @returns [Manifest] The loaded manifest.
			# @raises [CheckError] If the manifest is missing or malformed.
			def self.load(root)
				path = Pathname.new(root) + FILENAME
				new(JSON.parse(path.read))
			rescue Errno::ENOENT
				raise CheckError, "Static package manifest does not exist at #{path}!"
			rescue JSON::ParserError => error
				raise CheckError, "Could not parse #{path}: #{error.message}"
			end
			
			# Initialize a manifest with its serialized data.
			# @parameter data [Hash] The manifest data.
			def initialize(data)
				@data = data
			end
			
			# @attribute [Hash] The serialized manifest data.
			attr :data
			
			# Write the manifest into a static output directory.
			# @parameter root [String | Pathname] The static output directory.
			# @returns [Integer] The number of bytes written.
			def write(root)
				path = Pathname.new(root) + FILENAME
				path.write(JSON.pretty_generate(@data) + "\n")
			end
			
			# Extract the browser import map.
			# @returns [Hash] An import-map object containing the configured imports.
			def import_map
				{"imports" => @data.fetch("imports", {})}
			end
			
			# Check whether every manifested file exists with the expected content.
			# @parameter root [String | Pathname] The static output directory.
			# @returns [Boolean] Whether the directory exactly matches the manifest.
			def valid_tree?(root)
				root = Pathname.new(root)
				expected = []
				
				@data.fetch("packages").each do |name, package|
					package.fetch("files").each do |relative_path, digest|
						path = root + name + relative_path
						expected << path.relative_path_from(root).to_s
						
						return false unless path.file?
						return false unless Digest::SHA256.file(path).hexdigest == digest
					end
				end
				
				actual = root.glob("**/*", File::FNM_DOTMATCH).select(&:file?).map do |path|
					path.relative_path_from(root).to_s
				end
				actual.delete(FILENAME)
				
				actual.sort == expected.sort
			end
		end
	end
end
