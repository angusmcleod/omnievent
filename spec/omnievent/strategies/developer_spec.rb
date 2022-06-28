# frozen_string_literal: true

RSpec.describe OmniEvent::Strategies::Developer do
  let(:raw_data) { OmniEvent::Strategies::Developer.raw_data }

  before do
    OmniEvent::Builder.new do
      provider :developer
    end
  end

  describe "list_events" do
    before do
      @events = OmniEvent.list_events(:developer)
    end

    it "returns an event list" do
      expect(@events).to all(be_kind_of(OmniEvent::EventHash))
    end

    it "returns valid events" do
      expect(@events).to all(be_valid)
    end

    it "returns events with metadata" do
      expect(@events[0].metadata.id).to eq(raw_data["events"][0]["id"])
    end

    it "returns events with associated location data" do
      expect(@events[0].associated_data.location.country).to eq(raw_data["events"][0]["location"]["countryCode"])
    end

    it "returns events with associated virtual location data" do
      expect(@events[1].associated_data.virtual_location["entry_points"].first["type"]).to eq("video")
    end

    context "from_time" do
      before do
        Timecop.freeze(Time.local(1990))
      end

      after do
        Timecop.return
      end

      it "filters our events before the from_time" do
        OmniEvent::Strategies::Developer.instance_eval do
          def raw_data
            fixture = File.join(File.expand_path("../../..", __dir__), "spec", "fixtures", "list_events.json")
            raw = JSON.parse(File.open(fixture).read).to_h
            raw["events"][0]["start_time"] = Time.now.to_s
            raw["events"][0]["end_time"] = (Time.now + (60 * 60 * 2)).to_s
            raw["events"][1]["start_time"] = (Time.now + (60 * 60 * 24 * 60) + (60 * 60 * 2)).to_s
            raw["events"][1]["end_time"] = (Time.now + (60 * 60 * 24 * 60) + (60 * 60 * 4)).to_s
            raw
          end
        end

        events = OmniEvent.list_events(:developer, from_time: Time.now + (60 * 60 * 24 * 60))
        expect(events.size).to eq(1)
        expect(events[0].data.send("start_time").to_s).to eq(
          (Time.now + (60 * 60 * 24 * 60) + (60 * 60 * 2)).iso8601(3)
        )
      end

      it "works if the from_time is in the past" do
        OmniEvent::Strategies::Developer.instance_eval do
          def raw_data
            fixture = File.join(File.expand_path("../../..", __dir__), "spec", "fixtures", "list_events.json")
            raw = JSON.parse(File.open(fixture).read).to_h
            raw["events"][0]["start_time"] = (Time.now - (60 * 60 * 24 * 60)).to_s
            raw["events"][0]["end_time"] = (Time.now - (60 * 60 * 24 * 60) - (60 * 60 * 2)).to_s
            raw["events"][1]["start_time"] = Time.now.to_s
            raw["events"][1]["end_time"] = (Time.now + (60 * 60 * 2)).to_s
            raw
          end
        end

        events = OmniEvent.list_events(:developer, from_time: (Time.now - (60 * 60 * 24 * 60) - (60 * 60 * 2)))
        expect(events.size).to eq(2)
        expect(events[0].data.send("start_time")).to eq((Time.now - (60 * 60 * 24 * 60)).iso8601(3))
      end
    end
  end
end
