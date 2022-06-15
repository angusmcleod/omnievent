# frozen_string_literal: true

require "time"

RSpec.describe OmniEvent::EventHash do
  subject { OmniEvent::EventHash.new }

  it "converts a hash of data into a DataHash" do
    start_time = Time.now.iso8601
    subject.data = { start_time: start_time }
    expect(subject.data).to be_kind_of(OmniEvent::EventHash::DataHash)
    expect(subject.data.start_time).to eq(start_time)
  end

  it "converts a hash of metadata into a MetadataHash" do
    id = "1234567"
    subject.metadata = { id: id }
    expect(subject.metadata).to be_kind_of(OmniEvent::EventHash::MetadataHash)
    expect(subject.metadata.id).to eq(id)
  end

  it "has a subkey_class" do
    expect(OmniEvent::EventHash.subkey_class).to eq Hashie::Mash
  end

  describe "#valid?" do
    subject do
      OmniEvent::EventHash.new(
        provider: "eventbrite",
        data: { start_time: Time.now.iso8601, name: "My Event" },
        metadata: {}
      )
    end

    it "is valid with the right parameters" do
      expect(subject).to be_valid
    end

    it "requires a provider" do
      subject.provider = nil
      expect(subject).not_to be_valid
    end

    context "data" do
      it "requires a start" do
        subject.data.start_time = nil
        expect(subject).not_to be_valid
      end

      it "requires a name" do
        subject.data.name = nil
        expect(subject).not_to be_valid
      end

      it "only permits listed attributes" do
        subject.data.custom = "Custom data"
        expect(subject).not_to be_valid
      end

      context "validation" do
        it "validates valid times" do
          subject.data.end_time = "2022-06-12T12:41:13+02:00"
          expect(subject.data.end_time_valid?).to eq(true)
        end

        it "invalidates invalid times" do
          subject.data.end_time = "2022-06-15 16:42:26.97162 +0200"
          expect(subject.data.end_time_valid?).to eq(false)
        end

        it "validates valid timezones" do
          subject.data.timezone = "Europe/Copenhagen"
          expect(subject.data.timezone_valid?).to eq(true)
        end

        it "invalidates invalid timezones" do
          subject.data.timezone = "Copenhagen"
          expect(subject.data.timezone_valid?).to eq(false)
        end

        it "validates valid strings" do
          subject.data.name = "My Event"
          expect(subject.data.name_valid?).to eq(true)
        end

        it "invalidates invalid strings" do
          subject.data.name = { en: "My Event" }
          expect(subject.data.name_valid?).to eq(false)
        end

        it "validates valid statuses" do
          subject.data.status = "draft"
          expect(subject.data.status_valid?).to eq(true)
        end

        it "invalidates invalid statuses" do
          subject.data.status = "live"
          expect(subject.data.status_valid?).to eq(false)
        end

        it "validates valid url" do
          subject.data.url = "https://event-platform.com/events/my-event"
          expect(subject.data.url_valid?).to eq(true)
        end

        it "invalidates invalid url" do
          subject.data.url = "event-platform/events/my-event"
          expect(subject.data.url_valid?).to eq(false)
        end

        it "validates valid virtual" do
          subject.data.virtual = true
          expect(subject.data.virtual_valid?).to eq(true)
        end

        it "invalidates invalid virtual" do
          subject.data.virtual = { online: true }
          expect(subject.data.virtual_valid?).to eq(false)
        end
      end
    end

    context "metadata" do
      it "only permits listed attributes" do
        subject.metadata.custom = "Custom metadata"
        expect(subject).not_to be_valid
      end

      context "validation" do
        it "validates valid locales" do
          subject.metadata.locale = "en"
          expect(subject.metadata.locale_valid?).to eq(true)
        end

        it "invalidates invalid locales" do
          subject.metadata.locale = "pbj"
          expect(subject.metadata.locale_valid?).to eq(false)
        end

        it "validates valid taxonomies" do
          subject.metadata.taxonomies = %w[technology blockchain]
          expect(subject.metadata.taxonomies_valid?).to eq(true)
        end

        it "invalidates invalid taxonomies" do
          subject.metadata.taxonomies = [{ category: "technology" }, { tag: "blockchain" }]
          expect(subject.metadata.taxonomies_valid?).to eq(false)
        end
      end
    end
  end
end
