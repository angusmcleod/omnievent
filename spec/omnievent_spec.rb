# frozen_string_literal: true

RSpec.describe OmniEvent do
  it "has a version number" do
    expect(OmniEvent::VERSION).not_to be nil
  end

  describe ".strategies" do
    it "increases when a new strategy is made" do
      expect do
        OmniEvent::Strategies::ExampleStrategy.include OmniEvent::Strategy
      end.to change(described_class.strategies, :size).by(1)
      expect(described_class.strategies.last).to eq(OmniEvent::Strategies::ExampleStrategy)
    end
  end

  describe ".logger" do
    it "calls through to the configured logger" do
      allow(described_class).to receive(:config).and_return(double(logger: "custom_logger"))
      expect(described_class.logger).to eq("custom_logger")
    end
  end
end
