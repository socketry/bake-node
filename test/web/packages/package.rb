# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "web/packages/package"

describe Web::Packages::Package do
	it "validates package names" do
		expect do
			subject.new("../example")
		end.to raise_exception(Web::Packages::ConfigurationError, message: be =~ /Invalid package name/)
	end
	
	it "validates package options" do
		expect do
			subject.new("example", true)
		end.to raise_exception(Web::Packages::ConfigurationError, message: be =~ /must be an object/)
		
		expect do
			subject.new("example", "include" => [])
		end.to raise_exception(Web::Packages::ConfigurationError, message: be =~ /non-empty array/)
		
		expect do
			subject.new("example", "imports" => {"example" => false})
		end.to raise_exception(Web::Packages::ConfigurationError, message: be =~ /map strings/)
	end
	
	it "rejects paths outside the package" do
		expect do
			subject.new("example", "source" => "../outside")
		end.to raise_exception(Web::Packages::ConfigurationError, message: be =~ /remain within/)
		
		expect do
			subject.new("example", "include" => [""])
		end.to raise_exception(Web::Packages::ConfigurationError, message: be =~ /non-empty string/)
	end
end
