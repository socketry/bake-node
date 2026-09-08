# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "digest"
require "fileutils"
require "json"
require "pathname"
require "tmpdir"

require_relative "errors"
require_relative "manifest"

module Bake
	module Node
		class Static
			EXCLUDED_COMPONENTS = [".git", "node_modules"].freeze
			
			def initialize(configuration, output: nil)
				@configuration = configuration
				@output = configuration.output_path(output)
			end
			
			attr :configuration
			attr :output
			
			def update
				FileUtils.mkdir_p(@output.dirname)
				
				Dir.mktmpdir(".bake-node-", @output.dirname.to_s) do |temporary_root|
					temporary_root = Pathname.new(temporary_root)
					staging = temporary_root + "static"
					backup = temporary_root + "backup"
					
					build(staging)
					replace(staging, backup)
				end
				
				Manifest.load(@output)
			end
			
			def check
				installed = Manifest.load(@output)
				
				Dir.mktmpdir("bake-node-check-") do |temporary_root|
					desired = build(Pathname.new(temporary_root) + "static")
					
					return installed.data == desired.data && installed.valid_tree?(@output)
				end
			end
			
			def check!
				unless check
					raise CheckError, "Static Node.js packages are out of date. Run `bake node:packages:static`."
				end
				
				true
			end
			
			private
			
			def build(destination)
				FileUtils.mkdir_p(destination)
				
				packages = {}
				imports = {}
				
				@configuration.packages.each_value do |package|
					package_data, package_imports = install(package, destination)
					packages[package.name] = package_data
					
					package_imports.each do |specifier, path|
						if imports.key?(specifier)
							raise ConfigurationError, "Import specifier #{specifier.inspect} is configured more than once!"
						end
						
						imports[specifier] = path
					end
				end
				
				manifest = Manifest.build(base: @configuration.base, imports: imports, packages: packages)
				manifest.write(destination)
				manifest
			end
			
			def install(package, destination)
				package_path = @configuration.package_root + package.name
				
				unless package_path.directory?
					raise PackageError, "Package #{package.name} was not found at #{package_path}!"
				end
				
				package_root = package_path.realpath
				source = package.source || default_source(package_root)
				source_root = resolve_within(package_root, source, "source for #{package.name}")
				
				unless source_root.directory?
					raise PackageError, "Package source does not exist for #{package.name}: #{source_root}!"
				end
				
				paths = included_paths(package, source_root)
				install_root = destination + package.name
				files = {}
				
				paths.each do |relative_path|
					source_path = source_root + relative_path
					install_path = install_root + relative_path
					
					FileUtils.mkdir_p(install_path.dirname)
					FileUtils.cp(source_path, install_path)
					files[relative_path] = Digest::SHA256.file(install_path).hexdigest
				end
				
				package_json = read_package_json(package_root)
				imports = resolve_imports(package, install_root)
				
				[
					{
						"version" => package_json["version"],
						"source" => source,
						"files" => files.sort.to_h,
					},
					imports,
				]
			end
			
			def default_source(package_root)
				(package_root + "dist").directory? ? "dist" : "."
			end
			
			def included_paths(package, source_root)
				patterns = package.include_patterns || ["**/*"]
				
				paths = patterns.flat_map do |pattern|
					Dir.glob(pattern, File::FNM_DOTMATCH, base: source_root.to_s)
				end.uniq.sort.select do |relative_path|
					components = Pathname.new(relative_path).each_filename.to_a
					next false if components.any?{|component| EXCLUDED_COMPONENTS.include?(component)}
					
					path = source_root + relative_path
					next false unless path.file?
					
					resolve_within(source_root, relative_path, "included file for #{package.name}")
					true
				end
				
				if paths.empty?
					raise PackageError, "No files matched for #{package.name}!"
				end
				
				paths
			end
			
			def resolve_imports(package, install_root)
				package.imports.sort.to_h do |specifier, value|
					if value.match?(/\A(?:[a-z][a-z0-9+.-]*:|\/\/|\/)/i)
						[specifier, value]
					else
						path = install_root + value
						
						unless path.file?
							raise PackageError, "Import #{specifier.inspect} refers to a file which was not installed: #{value.inspect}!"
						end
						
						base = @configuration.base
						[specifier, "#{base}#{package.name}/#{value}"]
					end
				end
			end
			
			def read_package_json(package_root)
				path = package_root + "package.json"
				return {} unless path.file?
				
				JSON.parse(path.read)
			rescue JSON::ParserError => error
				raise PackageError, "Could not parse #{path}: #{error.message}"
			end
			
			def resolve_within(root, relative_path, description)
				path = (root + relative_path).realpath
				prefix = root.to_s + File::SEPARATOR
				
				unless path == root || path.to_s.start_with?(prefix)
					raise PackageError, "The #{description} escapes #{root}: #{relative_path.inspect}!"
				end
				
				path
			rescue Errno::ENOENT
				raise PackageError, "The #{description} does not exist: #{relative_path.inspect}!"
			end
			
			def replace(staging, backup)
				File.rename(@output, backup) if @output.exist?
				
				begin
					File.rename(staging, @output)
				rescue Exception
					File.rename(backup, @output) if backup.exist? && !@output.exist?
					raise
				end
			end
		end
	end
end
