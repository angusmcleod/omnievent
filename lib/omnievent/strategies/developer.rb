# frozen_string_literal: true

require "json"

module OmniEvent
  module Strategies
    # The Developer strategy can be used for testing.
    #
    # ## Usage
    #
    # All you need to do is put it in like any other strategy:
    #
    # @example Basic Usage
    #
    #   OmniEvent::Builder.new do
    #     provider :developer
    #   end
    #
    #   OmniEvent.event(:developer)
    #
    class Developer
      include OmniEvent::Strategy

      option :token, "12345"
      option :name, "developer"

      def raw_data
        fixture = File.join(File.expand_path("../../..", __dir__), "spec", "fixtures", "event.json")
        @raw_data ||= JSON.parse(File.open(fixture).read).to_h
      end

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

      def location
        raw_data.each_with_object({}) do |(raw_key, raw_value), result|
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

      def event
        OmniEvent::EventHash.new(
          provider: name,
          data: raw_data.slice(*OmniEvent::EventHash::DataHash.permitted_attributes),
          metadata: raw_data.slice(*OmniEvent::EventHash::MetadataHash.permitted_attributes),
          associated_data: {
            location: location
          }
        )
      end

      def event_list
        [
          event
        ]
      end
    end
  end
end
