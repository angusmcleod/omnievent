# frozen_string_literal: true

RSpec.describe OmniEvent::Strategies::Developer do
  before do
    OmniEvent::Builder.new do
      provider :developer
    end
  end

  def raw_data
    fixture = File.join(File.expand_path("../../..", __dir__), "spec", "fixtures", "event.json")
    @raw_data ||= JSON.parse(File.open(fixture).read).to_h
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

  it "returns event with metadata" do
    event = OmniEvent.event(:developer)
    expect(event.metadata.id).to eq(raw_data["id"])
  end

  it "returns event with associated data" do
    event = OmniEvent.event(:developer)
    expect(event.associated_data.location.country).to eq(raw_data["location"]["countryCode"])
  end
end
