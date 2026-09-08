# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "web/packages"

describe Web::Packages do
	it "has an initial version" do
		expect(Web::Packages::VERSION).to be == "0.1.0"
	end
end
