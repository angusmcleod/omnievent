# frozen_string_literal: true

RSpec.describe OmniEvent::Strategies::Developer do
  before do
    OmniEvent::Builder.new do
      provider :developer
    end
  end

  it "returns an event" do
    expect(OmniEvent.event(:developer)).to be_kind_of(OmniEvent::EventHash)
  end

  it "returns an event list" do
    expect(OmniEvent.event_list(:developer)).to all(be_kind_of(OmniEvent::EventHash))
  end

  it "returns valid events" do
    event = OmniEvent.event(:developer)
    expect(event).to be_valid
  end
end
