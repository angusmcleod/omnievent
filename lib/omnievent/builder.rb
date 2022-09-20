# frozen_string_literal: true

module OmniEvent
  # Builds strategies for the current instance of OmniAuth
  class Builder
    def initialize(&block)
      instance_eval(&block) if block_given?
    end

    # Configures the Builder.
    def configure(&block)
      OmniEvent.configure(&block)
    end

    # Allows arbitrary options to be passed to strategies.
    def options(options = false)
      return @options ||= {} if options == false

      @options = options
    end

    # Registers a provider.
    def provider(name, *args, **opts, &block)
      klass = OmniEvent.provider_class(name)
      raise MissingStrategy, "Could not find matching strategy for #{klass.inspect}." unless klass

      unless OmniEvent.strategies.include?(klass)
        raise StrategyNotIncluded, "Strategy for #{klass.inspect} has not been included properly."
      end

      OmniEvent.active_strategies[klass] = proc { klass.new(*args, **options.merge(opts), &block) }
    end
  end
end
