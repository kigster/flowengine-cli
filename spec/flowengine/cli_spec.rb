# frozen_string_literal: true

RSpec.describe FlowEngine::CLI do
  it "has a version number" do
    expect(FlowEngine::CLI::VERSION).not_to be_nil
  end

  it "has version 0.1.0" do
    expect(FlowEngine::CLI::VERSION).to eq("0.1.0")
  end

  it "defines an Error class" do
    expect(FlowEngine::CLI::Error).to be < StandardError
  end
end
