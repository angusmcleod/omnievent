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

  # The default logger.
  def self.default_logger
    logger = ::Logger.new($stdout)
    logger.progname = "omniauth"
    logger
  end

  # Get the configuration.
  def self.config
    Configuration.instance
  end

  # Setup the configuration.
  def self.configure
    yield config
  end

  # Get the current logger.
  def self.logger
    config.logger
  end

  # All available strategies.
  def self.strategies
    @strategies ||= []
  end

  # All active strategies.
  def self.active_strategies
    @active_strategies ||= ActiveStrategies.new
  end

  # Get event.
  def self.event(provider, opts = {})
    strategy_instance(provider).request(:event, opts)
  end

  # List events.
  def self.event_list(provider, opts = {})
    strategy_instance(provider).request(:event_list, opts)
  end

  def self.strategy_instance(provider)
    klass = provider_class(provider)

    raise MissingStrategy, "Could not find matching strategy for #{klass.inspect}." unless klass

    strategy_proc = active_strategies[klass]

    raise StrategyNotConfigured, "Strategy for #{klass.inspect} has not be configured." unless strategy_proc

    strategy_proc.call
  end

  def self.provider_class(provider)
    klass = OmniEvent::Utils.camelize(provider.to_s).to_s

    begin
      OmniEvent::Strategies.const_get(klass, false)
    rescue NameError
      false
    end
  end
end
