# frozen_string_literal: true

require "uri"
require "tzinfo"
require "iso-639"
require "time"

module OmniEvent
  # Utility methods
  module Utils
    module_function

    def camelize(word, first_letter_in_uppercase = true)
      return OmniEvent.config.camelizations[word.to_s] if OmniEvent.config.camelizations[word.to_s]

      if first_letter_in_uppercase
        word.to_s.gsub(%r{/(.?)}) do
          "::#{Regexp.last_match[1].upcase}"
        end.gsub(/(^|_)(.)/) { Regexp.last_match[2].upcase }
      else
        camelize(word).tap { |w| w[0] = w[0].downcase }
      end
    end

    def valid_time?(value)
      !!Time.iso8601(value)
    rescue ArgumentError
      false
    end

    def valid_timezone?(value)
      TZInfo::Timezone.all_identifiers.include?(value)
    end

    def valid_locale?(value)
      !!ISO_639.find_by_code(value)
    end

    def valid_url?(value)
      (URI.parse value).is_a? URI::HTTP
    rescue URI::InvalidURIError
      false
    end

    def valid_type?(value, type)
      case type
      when :boolean
        [true, false].include? value
      when :string
        value.is_a?(String)
      when :array
        value.is_a?(Array)
      else
        false
      end
    end

    def all_valid_type?(array, type)
      valid_type?(array, :array) && array.all? { |t| valid_type?(t, type) }
    end
  end
end
