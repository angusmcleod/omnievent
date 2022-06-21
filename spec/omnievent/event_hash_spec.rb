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
        metadata: {},
        associated_data: {}
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

    context "associated_data" do
      it "only permits listed attributes" do
        subject.associated_data.tickets = { id: "12345" }
        expect(subject).not_to be_valid
      end

      context "location" do
        it "requires a hash" do
          subject.associated_data.location = []
          expect(subject.associated_data.location_valid?).to eq(false)
        end

        context "validation" do
          it "validates valid location addresses" do
            subject.associated_data.location = { postal_code: "6000",
                                                 address: "827-905 Hay St, Perth WA 6000, Australia", city: "Perth" }
            expect(subject.associated_data.location_valid?).to eq(true)
          end

          it "invalidates invalid location addresses" do
            subject.associated_data.location = { postal_code: 6000,
                                                 address: "827-905 Hay St, Perth WA 6000, Australia", city: "Perth" }
            expect(subject.associated_data.location_valid?).to eq(false)
          end

          it "validates valid location country codes" do
            subject.associated_data.location = { country: "AU", address: "827-905 Hay St, Perth WA 6000, Australia",
                                                 city: "Perth" }
            expect(subject.associated_data.location_valid?).to eq(true)
          end

          it "invalidates invalid location country codes" do
            subject.associated_data.location = { country: "AUD", address: "827-905 Hay St, Perth WA 6000, Australia",
                                                 city: "Perth" }
            expect(subject.associated_data.location_valid?).to eq(false)
          end

          it "validates valid location coordinates" do
            subject.associated_data.location = { latitude: "31.9529", longitude: "115.8546" }
            expect(subject.associated_data.location_valid?).to eq(true)
          end

          it "invalidates invalid location coordinates" do
            subject.associated_data.location = { latitude: "190.9529", longitude: "115.8546" }
            expect(subject.associated_data.location_valid?).to eq(false)
          end

          it "validates valid location urls" do
            subject.associated_data.location = { latitude: "31.9529", longitude: "115.8546", url: "https://www.ptt.wa.gov.au/venues/his-majestys-theatre/" }
            expect(subject.associated_data.location_valid?).to eq(true)
          end

          it "invalidates invalid location urls" do
            subject.associated_data.location = { latitude: "31.9529", longitude: "115.8546",
                                                 url: "https/www.ptt.wa.gov.au/venues/his-majestys-theatre/" }
            expect(subject.associated_data.location_valid?).to eq(false)
          end

          it "invalidates invalid location coordinates" do
            subject.associated_data.location = { latitude: "190.9529", longitude: "115.8546" }
            expect(subject.associated_data.location_valid?).to eq(false)
          end
        end
      end

      context "virtual_location" do
        it "requires a hash" do
          subject.associated_data.virtual_location = []
          expect(subject.associated_data.virtual_location_valid?).to eq(false)
        end

        def virtual_location(entry_points); end

        context "validation" do
          it "validates valid virtual_location entry_point uris" do
            subject.associated_data.virtual_location = {
              entry_points: [{ uri: "https://video-conference.com/12345", type: "video", code: "1234",
                               label: "My Video Room" }]
            }
            expect(subject.associated_data.virtual_location_valid?).to eq(true)
          end

          it "invalidates invalid virtual_location entry_point uris" do
            subject.associated_data.virtual_location = {
              entry_points: [{ uri: "httpsvideo-conference.com/12345", type: "video", code: "1234",
                               label: "My Video Room" }]
            }
            expect(subject.associated_data.virtual_location_valid?).to eq(false)
          end

          it "validates valid virtual_location entry_point types" do
            subject.associated_data.virtual_location = {
              entry_points: [{ uri: "https://video-conference.com/12345", type: "video", code: "1234",
                               label: "My Video Room" }]
            }
            expect(subject.associated_data.virtual_location_valid?).to eq(true)
          end

          it "invalidates invalid virtual_location entry_point types" do
            subject.associated_data.virtual_location = {
              entry_points: [{ uri: "https://video-conference.com/12345", type: "zoom", code: "1234",
                               label: "My Video Room" }]
            }
            expect(subject.associated_data.virtual_location_valid?).to eq(false)
          end
        end
      end

      context "organizer" do
        it "requires a hash" do
          subject.associated_data.organizer = []
          expect(subject.associated_data.organizer_valid?).to eq(false)
        end

        context "validation" do
          it "validates valid organizer name" do
            subject.associated_data.organizer = { name: "Dance Society" }
            expect(subject.associated_data.organizer_valid?).to eq(true)
          end

          it "invalidates invalid organizer name" do
            subject.associated_data.organizer = { name: { en: "Dance Society" } }
            expect(subject.associated_data.organizer_valid?).to eq(false)
          end

          it "validates valid organizer email" do
            subject.associated_data.organizer = { name: "Dance Society", email: "joe@dance-society.com" }
            expect(subject.associated_data.organizer_valid?).to eq(true)
          end

          it "invalidates invalid organizer email" do
            subject.associated_data.organizer = { name: "Dance Society", email: "joe@dance-society." }
            expect(subject.associated_data.organizer_valid?).to eq(false)
          end

          it "validates valid organizer uris" do
            subject.associated_data.organizer = { name: "Dance Society", email: "joe@dance-society.com", uris: ["https://dance-society.com"] }
            expect(subject.associated_data.organizer_valid?).to eq(true)
          end

          it "invalidates invalid organizer uris" do
            subject.associated_data.organizer = { name: "Dance Society", email: "joe@dance-society.", uris: [1234] }
            expect(subject.associated_data.organizer_valid?).to eq(false)
          end
        end
      end

      context "registrations" do
        it "requires an array" do
          subject.associated_data.registrations = {}
          expect(subject.associated_data.registrations_valid?).to eq(false)
        end

        context "validation" do
          it "validates valid registration name" do
            subject.associated_data.registrations = [{ name: "Angus McLeod", email: "angus@test.com",
                                                       status: "confirmed" }]
            expect(subject.associated_data.registrations_valid?).to eq(true)
          end

          it "invalidates invalid registration name" do
            subject.associated_data.registrations = [{ name: { en: "Angus McLeod" }, email: "angus@test.com",
                                                       status: "confirmed" }]
            expect(subject.associated_data.registrations_valid?).to eq(false)
          end

          it "validates valid registration email" do
            subject.associated_data.registrations = [{ email: "angus@test.com", status: "confirmed" }]
            expect(subject.associated_data.registrations_valid?).to eq(true)
          end

          it "invalidates invalid registration email" do
            subject.associated_data.registrations = [{ email: "angus@test.", status: "confirmed" }]
            expect(subject.associated_data.registrations_valid?).to eq(false)
          end

          it "validates valid registration status" do
            subject.associated_data.registrations = [{ email: "angus@test.com", status: "confirmed" }]
            expect(subject.associated_data.registrations_valid?).to eq(true)
          end

          it "invalidates invalid registration email" do
            subject.associated_data.registrations = [{ email: "angus@test.com", status: "rejected" }]
            expect(subject.associated_data.registrations_valid?).to eq(false)
          end
        end
      end
    end
  end
end
