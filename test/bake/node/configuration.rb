# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "sus/fixtures/temporary_directory_context"

require "bake/node/configuration"

describe Bake::Node::Configuration do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	def write_package_json(data)
		File.write(File.join(root, "package.json"), JSON.generate(data))
	end
	
	it "uses direct dependencies by default" do
		write_package_json("dependencies" => {"@socketry/live" => "^1.0.0"})
		
		configuration = subject.load(root)
		
		expect(configuration.packages.keys).to be == ["@socketry/live"]
		expect(configuration.output_path).to be == Pathname.new(root) + "public/_components"
	end
	
	it "supports package overrides and additional workspace packages" do
		write_package_json(
			"dependencies" => {"example" => "^1.0.0", "unused" => "^1.0.0"},
			"bake-node" => {
				"packages" => {
					"example" => {"source" => "dist", "include" => ["example.js"]},
					"unused" => false,
					"@socketry/internal" => true,
				},
			},
		)
		
		configuration = subject.load(root)
		
		expect(configuration.packages.keys).to be == ["@socketry/internal", "example"]
		expect(configuration.packages["example"].source).to be == "dist"
	end
	
	it "rejects output outside the project" do
		write_package_json("bake-node" => {"output" => "../public"})
		
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /remain within/)
	end
	
	it "supports an explicit package list" do
		write_package_json(
			"dependencies" => {"unused" => "*"},
			"bake-node" => {"packages" => ["one", "two"]},
		)
		
		expect(subject.load(root).packages.keys).to be == ["one", "two"]
	end
	
	it "reports malformed configuration" do
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /Could not find/)
		
		File.write(File.join(root, "package.json"), "{")
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /Could not parse/)
		
		write_package_json([])
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /must contain an object/)
		
		write_package_json("bake-node" => [])
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /configuration must be an object/)
		
		write_package_json("dependencies" => [])
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /dependencies must be an object/)
		
		write_package_json("bake-node" => {"packages" => "example"})
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /packages must be an array or object/)
		
		write_package_json("bake-node" => {"base" => "/components"})
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /ending in/)
		
		write_package_json("bake-node" => {"packageRoot" => ""})
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /non-empty string/)
	end
end
