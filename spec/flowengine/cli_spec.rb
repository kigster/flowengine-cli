# frozen_string_literal: true

RSpec.describe FlowEngine::CLI do
  it "has a version number" do
    expect(FlowEngine::CLI::VERSION).not_to be_nil
  end

  it "defines an Error class" do
    expect(FlowEngine::CLI::Error).to be < StandardError
  end
end
