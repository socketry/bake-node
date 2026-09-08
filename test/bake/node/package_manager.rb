# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "sus/fixtures/temporary_directory_context"

require "bake/node/configuration"
require "bake/node/package_manager"

describe Bake::Node::PackageManager do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	def configuration(package_json = {})
		File.write(File.join(root, "package.json"), JSON.generate(package_json))
		Bake::Node::Configuration.load(root)
	end
	
	it "uses the packageManager declaration" do
		manager = subject.detect(configuration("packageManager" => "pnpm@10.0.0"), environment: {})
		
		expect(manager.name).to be == "pnpm"
		expect(manager.install_command(frozen: true)).to be == ["pnpm", "install", "--frozen-lockfile"]
	end
	
	it "constructs immutable installation commands" do
		expect(subject.new(root, "npm").install_command(frozen: true)).to be == ["npm", "ci"]
		expect(subject.new(root, "yarn").install_command(frozen: true)).to be == ["yarn", "install", "--immutable"]
		expect(subject.new(root, "bun").install_command(frozen: true)).to be == ["bun", "install", "--frozen-lockfile"]
	end
	
	it "detects the package manager from its lock file" do
		File.write(File.join(root, "yarn.lock"), "")
		manager = subject.detect(configuration, environment: {})
		
		expect(manager.name).to be == "yarn"
	end
	
	it "honors the environment and otherwise falls back to npm" do
		manager = subject.detect(configuration("packageManager" => "npm@10"), environment: {"NODE_PACKAGE_MANAGER" => "bun"})
		expect(manager.name).to be == "bun"
		
		expect(subject.detect(configuration, environment: {}).name).to be == "npm"
	end
	
	it "rejects ambiguous lock files" do
		File.write(File.join(root, "package-lock.json"), "{}")
		File.write(File.join(root, "pnpm-lock.yaml"), "")
		
		expect do
			subject.detect(configuration, environment: {})
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /Multiple package manager/)
	end
	
	it "rejects invalid package manager declarations" do
		expect do
			subject.detect(configuration("packageManager" => true), environment: {})
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /must be a string/)
		
		expect do
			subject.new(root, "other")
		end.to raise_exception(Bake::Node::ConfigurationError, message: be =~ /Unsupported/)
	end
	
	it "runs package manager commands" do
		commands = []
		manager = subject.new(root, "npm")
		manager.define_singleton_method(:system) do |*arguments, **options|
			commands << [arguments, options]
			true
		end
		
		manager.install
		manager.run("test")
		
		expect(commands).to be == [
			[["npm", "install"], {chdir: root.to_s}],
			[["npm", "run", "test"], {chdir: root.to_s}],
		]
	end
	
	it "reports invalid and failed scripts" do
		manager = subject.new(root, "npm")
		
		expect do
			manager.run("")
		end.to raise_exception(ArgumentError, message: be =~ /non-empty string/)
		
		manager.define_singleton_method(:system) do |*arguments, **options|
			false
		end
		
		expect do
			manager.run("test")
		end.to raise_exception(Bake::Node::Error, message: be =~ /Command failed/)
	end
end
