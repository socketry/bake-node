# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "sus/fixtures/temporary_directory_context"

require "bake/node/manifest"

describe Bake::Node::Manifest do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	it "writes, loads and validates a static tree" do
		package_root = Pathname.new(root) + "example"
		package_root.mkpath
		(package_root + "example.js").write("example")
		
		manifest = subject.build(
			base: "/components/",
			imports: {"example" => "/components/example/example.js"},
			packages: {
				"example" => {
					"files" => {"example.js" => Digest::SHA256.hexdigest("example")},
				},
			},
		)
		manifest.write(root)
		
		expect(File).to be(:exist?, Pathname.new(root) + ".manifest.json")
		expect(File).not.to be(:exist?, Pathname.new(root) + ".bake-node.json")
		
		loaded = subject.load(root)
		expect(loaded.import_map).to be == {"imports" => {"example" => "/components/example/example.js"}}
		expect(loaded.valid_tree?(root)).to be == true
		
		(package_root + "extra.js").write("extra")
		expect(loaded.valid_tree?(root)).to be == false
	end
	
	it "detects missing and modified files" do
		manifest = subject.new(
			"packages" => {
				"example" => {"files" => {"example.js" => Digest::SHA256.hexdigest("expected")}},
			},
		)
		
		expect(manifest.valid_tree?(root)).to be == false
		
		package_root = Pathname.new(root) + "example"
		package_root.mkpath
		(package_root + "example.js").write("modified")
		expect(manifest.valid_tree?(root)).to be == false
	end
	
	it "reports missing and invalid manifests" do
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::CheckError, message: be =~ /does not exist/)
		
		Pathname.new(root).join(subject::FILENAME).write("{")
		expect do
			subject.load(root)
		end.to raise_exception(Bake::Node::CheckError, message: be =~ /Could not parse/)
	end
end
