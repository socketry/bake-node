# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "sus/fixtures/temporary_directory_context"

require "bake/node/controller"

describe Bake::Node::Controller do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	def write(path, content)
		path = Pathname.new(root) + path
		path.dirname.mkpath
		path.write(content)
	end
	
	it "materializes, checks and describes configured packages" do
		write("package.json", JSON.generate(
			"dependencies" => {"example" => "*"},
			"bake-node" => {
				"packages" => {
					"example" => {"include" => ["example.js"], "imports" => {"example" => "example.js"}},
				},
			},
		))
		write("node_modules/example/package.json", JSON.generate("version" => "1.0.0"))
		write("node_modules/example/example.js", "example")
		
		controller = subject.new(root)
		controller.static
		expect(controller.check).to be == true
		expect(JSON.parse(controller.import_map)).to be == {
			"imports" => {"example" => "/_components/example/example.js"},
		}
	end
	
	it "delegates installation and scripts to the package manager" do
		write("package.json", "{}")
		controller = subject.new(root)
		expect(controller.send(:package_manager).name).to be == "npm"
		
		calls = []
		manager = Object.new
		manager.define_singleton_method(:install) do |frozen:|
			calls << [:install, frozen]
		end
		manager.define_singleton_method(:run) do |script|
			calls << [:run, script]
		end
		controller.instance_variable_set(:@package_manager, manager)
		
		controller.install(frozen: true)
		controller.run("test:unit")
		expect(calls).to be == [[:install, true], [:run, "test:unit"]]
	end
end
