# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "digest"
require "json"
require "pathname"

require_relative "errors"

module Bake
	module Node
		class Manifest
			FILENAME = ".bake-node.json"
			
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
			
			def self.load(root)
				path = Pathname.new(root) + FILENAME
				new(JSON.parse(path.read))
			rescue Errno::ENOENT
				raise CheckError, "Static package manifest does not exist at #{path}!"
			rescue JSON::ParserError => error
				raise CheckError, "Could not parse #{path}: #{error.message}"
			end
			
			def initialize(data)
				@data = data
			end
			
			attr :data
			
			def write(root)
				path = Pathname.new(root) + FILENAME
				path.write(JSON.pretty_generate(@data) + "\n")
			end
			
			def import_map
				{"imports" => @data.fetch("imports", {})}
			end
			
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
