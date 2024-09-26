# frozen_string_literal: true

require "timecop"
require "active_support"
require "active_support/core_ext/numeric/time"

RSpec.describe OmniEvent::Strategies::Developer do
  let(:raw_data) { described_class.new.raw_data }
  let(:event_data) do
    {
      start_time: "2017-04-15T11:00:00.0000000",
      end_time: "2017-04-15T12:00:00.0000000",
      name: "Let's go brunch",
      description: "Does noon work for you?",
      url: "https://event.com/brunch"
    }
  end

  before do
    OmniEvent::Builder.new do
      provider :developer
    end
  end

  describe "list_events" do
    it "returns an event list" do
      events = OmniEvent.list_events(:developer)

      expect(events).to all(be_kind_of(OmniEvent::EventHash))
    end

    it "returns valid events" do
      events = OmniEvent.list_events(:developer)

      expect(events).to all(be_valid)
    end

    it "returns events with metadata" do
      events = OmniEvent.list_events(:developer)

      expect(events[0].metadata.uid).to eq(raw_data["events"][0]["id"])
    end

    it "returns events with associated location data" do
      events = OmniEvent.list_events(:developer)

      expect(events[0].associated_data.location.country).to eq(raw_data["events"][0]["location"]["countryCode"])
    end

    it "returns events with associated virtual location data" do
      events = OmniEvent.list_events(:developer)

      expect(events[1].associated_data.virtual_location["entry_points"].first["type"]).to eq("video")
    end

    context "from_time" do
      before do
        Timecop.freeze(Time.local(1990))
      end

      after do
        Timecop.return
      end

      it "filters our events before the from_time" do
        described_class.class_eval do
          def raw_data
            raw = JSON.parse(File.open(options.uri).read).to_h
            raw["events"][0]["start_time"] = Time.now.to_s
            raw["events"][0]["end_time"] = 2.hours.from_now.to_s
            raw["events"][1]["start_time"] = (60.days.from_now + 2.hours).to_s
            raw["events"][1]["end_time"] = (60.days.from_now + 4.hours).to_s
            raw
          end
        end

        events = OmniEvent.list_events(:developer, from_time: Time.now + 60.days)
        expect(events.size).to eq(1)
        expect(events[0].data.send("start_time").to_s).to eq(
          (Time.now + 60.days + 2.hours).iso8601
        )
      end

      it "works if the from_time is in the past" do
        described_class.class_eval do
          def raw_data
            raw = JSON.parse(File.open(options.uri).read).to_h
            raw["events"][0]["start_time"] = 60.days.ago.to_s
            raw["events"][0]["end_time"] = (60.days.ago - 2.hours).to_s
            raw["events"][1]["start_time"] = Time.now.to_s
            raw["events"][1]["end_time"] = 2.hours.from_now.to_s
            raw
          end
        end

        events = OmniEvent.list_events(:developer, from_time: 60.days.ago - 2.hours)
        expect(events.size).to eq(2)
        expect(events[0].data.send("start_time")).to eq(60.days.ago.iso8601)
      end
    end

    context "to_time" do
      before do
        Timecop.freeze(Time.local(1990))
      end

      after do
        Timecop.return
      end

      it "filters out events after the to_time" do
        described_class.class_eval do
          def raw_data
            raw = JSON.parse(File.open(options.uri).read).to_h
            raw["events"][0]["start_time"] = Time.now.to_s
            raw["events"][0]["end_time"] = 2.hours.from_now.to_s
            raw["events"][1]["start_time"] = (60.days.from_now + 2.hours).to_s
            raw["events"][1]["end_time"] = (60.days.from_now + 4.hours).to_s
            raw
          end
        end

        events = OmniEvent.list_events(:developer, to_time: 60.days.from_now)
        expect(events.size).to eq(1)
        expect(events[0].data.send("start_time").to_s).to eq(Time.now.iso8601)
      end
    end

    context "match_name" do
      it "filters out events without matching names" do
        described_class.class_eval do
          def raw_data
            raw = JSON.parse(File.open(options.uri).read).to_h
            raw["events"][0]["name"] = "the match"
            raw
          end
        end

        events = OmniEvent.list_events(:developer, match_name: "the match")
        expect(events.size).to eq(1)
        expect(events[0].data.name).to eq("the match")
      end
    end
  end

  describe "create_event" do
    it "returns an event" do
      event = OmniEvent.create_event(
        :developer,
        event: OmniEvent::EventHash.new(
          provider: :developer,
          data: event_data
        )
      )
      expect(event).to be_kind_of(OmniEvent::EventHash)
      expect(event.data.start_time).to eq(event_data[:start_time])
      expect(event.data.end_time).to eq(event_data[:end_time])
      expect(event.data.name).to eq(event_data[:name])
      expect(event.data.description).to eq(event_data[:description])
      expect(event.data.url).to eq(event_data[:url])
    end
  end

  describe "update_event" do
    it "returns an event" do
      event = OmniEvent.update_event(
        :developer,
        event: OmniEvent::EventHash.new(
          provider: :developer,
          data: event_data
        )
      )
      expect(event).to be_kind_of(OmniEvent::EventHash)
      expect(event.data.start_time).to eq(event_data[:start_time])
      expect(event.data.end_time).to eq(event_data[:end_time])
      expect(event.data.name).to eq(event_data[:name])
      expect(event.data.description).to eq(event_data[:description])
      expect(event.data.url).to eq(event_data[:url])
    end
  end

  describe "destroy_event" do
    it "returns an boolean" do
      event = OmniEvent.destroy_event(
        :developer,
        event: OmniEvent::EventHash.new(
          provider: :developer,
          data: event_data
        )
      )
      expect(event).to eq(true)
    end
  end
end
