# frozen_string_literal: true

require "logger"

# Base module for OmniEvent
module OmniEvent
  class Error < StandardError; end
  class MissingStrategy < StandardError; end
  class StrategyNotIncluded < StandardError; end
  class StrategyNotConfigured < StandardError; end

  module Strategies
    autoload :Developer, "omnievent/strategies/developer"
  end

  autoload :Utils, "omnievent/utils"
  autoload :Configuration, "omnievent/configuration"
  autoload :Strategy, "omnievent/strategy"
  autoload :Builder, "omnievent/builder"
  autoload :KeyStore, "omnievent/key_store"
  autoload :EventHash, "omnievent/event_hash"

  class ActiveStrategies < OmniEvent::KeyStore; end

  EVENT_LIST_OPTIONS = %i[
    from_time
  ].freeze

  class << self
    # The default logger.
    def default_logger
      logger = ::Logger.new($stdout)
      logger.progname = "omniauth"
      logger
    end

    # Get the configuration.
    def config
      Configuration.instance
    end

    # Setup the configuration.
    def configure
      yield config
    end

    # Get the current logger.
    def logger
      config.logger
    end

    # All available strategies.
    def strategies
      @strategies ||= []
    end

    # All active strategies.
    def active_strategies
      @active_strategies ||= ActiveStrategies.new
    end

    # List events.
    def list_events(provider = nil, opts = {})
      raise ArgumentError, "You need to pass a provider name as the first argument." unless provider

      opts = opts.slice(*EVENT_LIST_OPTIONS)

      strategy_instance(provider).request(:list_events, opts)
    end

    def strategy_instance(provider)
      klass = provider_class(provider)

      raise MissingStrategy, "Could not find matching strategy for #{klass.inspect}." unless klass

      strategy_proc = active_strategies[klass]

      raise StrategyNotConfigured, "Strategy for #{klass.inspect} has not be configured." unless strategy_proc

      strategy_proc.call
    end

    def provider_class(provider)
      klass = OmniEvent::Utils.camelize(provider.to_s).to_s

      begin
        OmniEvent::Strategies.const_get(klass, false)
      rescue NameError
        false
      end
    end
  end
end
