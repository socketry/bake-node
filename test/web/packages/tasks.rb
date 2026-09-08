# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "bake/context"

describe "web-packages tasks" do
	let(:context) {Bake::Context.load}
	
	it "exports Node.js package tasks" do
		expect(context.lookup("web:packages:install")).not.to be_nil
		expect(context.lookup("web:packages:test")).not.to be_nil
		expect(context.lookup("web:packages:update")).not.to be_nil
		expect(context.lookup("web:packages:check")).not.to be_nil
		expect(context.lookup("web:packages:import_map:show")).not.to be_nil
	end
end
