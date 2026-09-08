# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "fileutils"
require "json"
require "sus/fixtures/temporary_directory_context"

require "web/packages/configuration"
require "web/packages/projection"

describe Web::Packages::Projection do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	def write(path, content)
		path = File.join(root, path)
		FileUtils.mkdir_p(File.dirname(path))
		File.write(path, content)
	end
	
	def configuration(packages)
		write("package.json", JSON.generate(
			"dependencies" => packages.keys.to_h{|name| [name, "*"]},
			"web-packages" => {"packages" => packages},
		))
		
		Web::Packages::Configuration.load(root)
	end
	
	it "materializes selected package files and an import map" do
		write("node_modules/@socketry/live/package.json", JSON.generate("name" => "@socketry/live", "version" => "1.2.3"))
		write("node_modules/@socketry/live/Live.js", "export class Live {}")
		write("node_modules/@socketry/live/test/Live.js", "unused")
		
		projection = subject.new(configuration(
			"@socketry/live" => {
				"include" => ["Live.js"],
				"imports" => {"live" => "Live.js"},
			},
		))
		manifest = projection.update
		
		expect(File.read(File.join(root, "public/_components/@socketry/live/Live.js"))).to be == "export class Live {}"
		expect(File).not.to be(:exist?, File.join(root, "public/_components/@socketry/live/test/Live.js"))
		expect(manifest.import_map).to be == {
			"imports" => {"live" => "/_components/@socketry/live/Live.js"},
		}
		expect(projection.check).to be == true
	end
	
	it "supports explicit distribution roots and removes stale packages" do
		write("node_modules/example/package.json", JSON.generate("version" => "2.0.0"))
		write("node_modules/example/dist/example.js", "example")
		write("node_modules/example/source.js", "unused")
		write("public/_components/stale/old.js", "stale")
		
		subject.new(configuration(
			"example" => {"source" => "dist", "include" => ["example.js"]},
		)).update
		
		expect(File.read(File.join(root, "public/_components/example/example.js"))).to be == "example"
		expect(File).not.to be(:exist?, File.join(root, "public/_components/example/source.js"))
		expect(File).not.to be(:exist?, File.join(root, "public/_components/stale"))
	end
	
	it "uses a distribution directory by default when present" do
		write("node_modules/example/package.json", "{}")
		write("node_modules/example/dist/example.js", "distribution")
		write("node_modules/example/source.js", "source")
		
		manifest = subject.new(configuration("example" => true)).update
		
		expect(File.read(File.join(root, "public/_components/example/example.js"))).to be == "distribution"
		expect(File).not.to be(:exist?, File.join(root, "public/_components/example/source.js"))
		expect(manifest.data.dig("packages", "example", "source")).to be == "dist"
	end
	
	it "preserves existing output when validation fails" do
		write("node_modules/example/package.json", "{}")
		write("node_modules/example/example.js", "example")
		write("public/_components/existing.js", "existing")
		
		projection = subject.new(configuration(
			"example" => {"include" => ["missing.js"]},
		))
		
		expect do
			projection.update
		end.to raise_exception(Web::Packages::PackageError)
		expect(File.read(File.join(root, "public/_components/existing.js"))).to be == "existing"
	end
	
	it "detects modified projection output" do
		write("node_modules/example/package.json", "{}")
		write("node_modules/example/example.js", "example")
		
		projection = subject.new(configuration("example" => {"include" => ["example.js"]}))
		projection.update
		write("public/_components/example/example.js", "modified")
		
		expect(projection.check).to be == false
	end
	
	it "raises when projection output is out of date" do
		write("node_modules/example/example.js", "example")
		projection = subject.new(configuration("example" => {"include" => ["example.js"]}))
		projection.update
		expect(projection.check!).to be == true
		
		write("public/_components/example/example.js", "modified")
		expect do
			projection.check!
		end.to raise_exception(Web::Packages::CheckError, message: be =~ /out of date/)
	end
	
	it "copies complete packages while excluding nested installations" do
		write("node_modules/example/package.json", "{}")
		write("node_modules/example/example.js", "example")
		write("node_modules/example/.metadata", "metadata")
		write("node_modules/example/node_modules/nested/index.js", "nested")
		write("node_modules/example/.git/config", "git")
		
		subject.new(configuration("example" => true)).update
		
		expect(File).to be(:exist?, File.join(root, "public/_components/example/example.js"))
		expect(File).to be(:exist?, File.join(root, "public/_components/example/.metadata"))
		expect(File).not.to be(:exist?, File.join(root, "public/_components/example/node_modules"))
		expect(File).not.to be(:exist?, File.join(root, "public/_components/example/.git"))
	end
	
	it "supports external imports and rejects duplicate specifiers" do
		write("node_modules/one/one.js", "one")
		write("node_modules/two/two.js", "two")
		
		projection = subject.new(configuration(
			"one" => {"include" => ["one.js"], "imports" => {"cdn" => "https://example.com/module.js"}},
		))
		expect(projection.update.import_map).to be == {"imports" => {"cdn" => "https://example.com/module.js"}}
		
		duplicate = subject.new(configuration(
			"one" => {"include" => ["one.js"], "imports" => {"example" => "one.js"}},
			"two" => {"include" => ["two.js"], "imports" => {"example" => "two.js"}},
		))
		expect do
			duplicate.update
		end.to raise_exception(Web::Packages::ConfigurationError, message: be =~ /configured more than once/)
	end
	
	it "reports missing packages, sources, files and imports" do
		expect do
			subject.new(configuration("missing" => true)).update
		end.to raise_exception(Web::Packages::PackageError, message: be =~ /was not found/)
		
		write("node_modules/example/package.json", "{}")
		write("node_modules/example/file.js", "file")
		
		expect do
			subject.new(configuration("example" => {"source" => "missing"})).update
		end.to raise_exception(Web::Packages::PackageError, message: be =~ /does not exist/)
		
		expect do
			subject.new(configuration("example" => {"source" => "file.js"})).update
		end.to raise_exception(Web::Packages::PackageError, message: be =~ /Package source does not exist/)
		
		expect do
			subject.new(configuration("example" => {"include" => ["absent.js"]})).update
		end.to raise_exception(Web::Packages::PackageError, message: be =~ /No files matched/)
		
		expect do
			subject.new(configuration(
				"example" => {"include" => ["file.js"], "imports" => {"missing" => "missing.js"}},
			)).update
		end.to raise_exception(Web::Packages::PackageError, message: be =~ /was not installed/)
	end
	
	it "reports invalid installed package metadata" do
		write("node_modules/example/package.json", "{")
		write("node_modules/example/example.js", "example")
		
		expect do
			subject.new(configuration("example" => {"include" => ["example.js"]})).update
		end.to raise_exception(Web::Packages::PackageError, message: be =~ /Could not parse/)
	end
	
	it "restores output when replacement fails" do
		write("package.json", "{}")
		write("public/_components/existing.js", "existing")
		
		projection = subject.new(Web::Packages::Configuration.load(root))
		temporary_root = Pathname.new(Dir.mktmpdir)
		
		expect do
			projection.send(:replace, temporary_root + "missing", temporary_root + "backup")
		end.to raise_exception(Errno::ENOENT)
		
		expect(File.read(File.join(root, "public/_components/existing.js"))).to be == "existing"
	end
	
	it "rejects symbolic links which escape the package" do
		write("outside.js", "outside")
		write("node_modules/example/package.json", "{}")
		File.symlink(File.join(root, "outside.js"), File.join(root, "node_modules/example/escape.js"))
		
		projection = subject.new(configuration("example" => {"include" => ["escape.js"]}))
		
		expect do
			projection.update
		end.to raise_exception(Web::Packages::PackageError, message: be =~ /escapes/)
	end
end
