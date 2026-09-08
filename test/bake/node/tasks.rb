# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "bake/context"

describe "bake-node tasks" do
	let(:context) {Bake::Context.load}
	
	it "exports Node.js package tasks" do
		expect(context.lookup("node:install")).not.to be_nil
		expect(context.lookup("node:test")).not.to be_nil
		expect(context.lookup("node:packages:static")).not.to be_nil
		expect(context.lookup("node:packages:check")).not.to be_nil
		expect(context.lookup("node:importmap:show")).not.to be_nil
	end
end
