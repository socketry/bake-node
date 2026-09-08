# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "bake/node"

describe Bake::Node do
	it "has an initial version" do
		expect(Bake::Node::VERSION).to be == "0.0.1"
	end
end
