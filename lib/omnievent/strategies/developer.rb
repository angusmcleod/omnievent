# frozen_string_literal: true

require "json"

module OmniEvent
  module Strategies
    # The Developer strategy can be used for testing purposes.
    #
    # ## Usage
    #
    # All you need to do is add it in like any other strategy:
    #
    # @example Basic Usage
    #
    #   OmniEvent::Builder.new do
    #     provider :developer
    #   end
    #
    class Developer
      include OmniEvent::Strategy

      option :name, "developer"
      option :uri, File.join(File.expand_path("../../..", __dir__), "spec", "fixtures", "list_events.json")

      def raw_data
        @raw_data ||= JSON.parse(File.open(options.uri).read).to_h
      end

      def raw_events
        raw_data["events"]
      end

      def event_hash(raw_event)
        event = OmniEvent::EventHash.new(
          provider: name,
          data: raw_event.slice(*OmniEvent::EventHash::DataHash.permitted_attributes),
          metadata: raw_event.slice(*OmniEvent::EventHash::MetadataHash.permitted_attributes),
          associated_data: {
            location: map_location(raw_event["location"]),
            virtual_location: raw_event["virtual_location"]
          }
        )

        event.data.start_time = format_time(event.data.start_time)
        event.data.end_time = format_time(event.data.end_time)
        event.metadata.created_at = format_time(event.metadata.created_at)
        event.metadata.updated_at = format_time(event.metadata.updated_at)
        event.metadata.uid = raw_event["id"]

        event
      end

      def authorized?
        true
      end

      protected

      def location_key_map
        {
          countryCode: "country",
          latitude: "latitude",
          longitude: "longitude",
          address1: "address",
          address2: "address",
          address3: "address",
          city: "city",
          postalCode: "postal_code"
        }
      end

      def map_location(raw_location)
        raw_location.each_with_object({}) do |(raw_key, raw_value), result|
          next unless location_key_map[raw_key.to_sym]

          key = location_key_map[raw_key.to_sym]
          value = result[key]
          if value && key == "address"
            value += " #{raw_value}"
          else
            value = raw_value
          end
          result[key] = value
        end
      end
    end
  end
end
