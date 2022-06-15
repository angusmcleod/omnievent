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

      def event
        OmniEvent::EventHash.new(
          provider: name,
          data: raw_data.slice(*OmniEvent::EventHash::DataHash.permitted_attributes),
          metadata: raw_data.slice(*OmniEvent::EventHash::MetadataHash.permitted_attributes)
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
