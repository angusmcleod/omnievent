# frozen_string_literal: true

RSpec.describe OmniEvent::Configuration do
  it "class methods set individual options" do
    described_class.logger = "custom_logger"
    expect(described_class.logger).to eq("custom_logger")
  end

  it "is callable from .configure" do
    OmniEvent.configure do |c|
      expect(c).to be_kind_of(described_class)
    end
  end
end
