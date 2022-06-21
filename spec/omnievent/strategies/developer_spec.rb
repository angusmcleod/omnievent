# frozen_string_literal: true

RSpec.describe OmniEvent::Strategies::Developer do
  before do
    OmniEvent::Builder.new do
      provider :developer
    end
  end

  def raw_data
    fixture = File.join(File.expand_path("../../..", __dir__), "spec", "fixtures", "event_list.json")
    @raw_data ||= JSON.parse(File.open(fixture).read).to_h
  end

  it "returns an event list" do
    expect(OmniEvent.event_list(:developer)).to all(be_kind_of(OmniEvent::EventHash))
  end

  it "returns valid events" do
    expect(OmniEvent.event_list(:developer)).to all(be_valid)
  end

  it "returns events with metadata" do
    event = OmniEvent.event_list(:developer)[0]
    expect(event.metadata.id).to eq(raw_data["events"][0]["id"])
  end

  it "returns events with associated location data" do
    event = OmniEvent.event_list(:developer)[0]
    expect(event.associated_data.location.country).to eq(raw_data["events"][0]["location"]["countryCode"])
  end

  it "returns events with associated virtual location data" do
    event = OmniEvent.event_list(:developer)[1]
    expect(event.associated_data.virtual_location["entry_points"].first["type"]).to eq("video")
  end
end
