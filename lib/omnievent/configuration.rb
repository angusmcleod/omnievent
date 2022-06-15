# frozen_string_literal: true

require "singleton"

module OmniEvent
  # Configuration class.
  class Configuration
    include Singleton

    OPTIONS = %i[
      logger
      camelizations
    ].freeze

    attr_accessor :data

    # :nodoc
    def initialize
      @data = {}
      set_defaults
    end

    OPTIONS.each do |o|
      define_method o do
        @data[o]
      end
      define_method "#{o}=" do |value|
        @data[o] = value
      end
    end

    def configure(options)
      Util.recursive_hash_merge(@data, options)
    end

    def set_defaults
      @data[:logger] = ::OmniEvent.default_logger
      @data[:camelizations] = {}
    end

    instance_eval(OPTIONS.map do |option|
      o = option.to_s
      <<-METHODS
      def #{o}
        instance.data[:#{o}]
      end

      def #{o}=(value)
        instance.data[:#{o}] = value
      end
      METHODS
    end.join("\n\n"))

    def self.set_defaults
      instance.set_defaults
    end
  end
end
