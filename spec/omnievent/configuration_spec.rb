# frozen_string_literal: true

RSpec.describe OmniEvent::Configuration do
  it "class methods set individual options" do
    OmniEvent::Configuration.logger = "custom_logger"
    expect(OmniEvent::Configuration.logger).to eq("custom_logger")
  end

  it "is callable from .configure" do
    OmniEvent.configure do |c|
      expect(c).to be_kind_of(OmniEvent::Configuration)
    end
  end
end
