# frozen_string_literal: true

module OmniEvent
  # The Strategy is the base unit of OmniEvent's ability to handle
  # multiple event providers. It's substantially based on OmniAuth::Strategy.
  module Strategy
    class Options < OmniEvent::KeyStore; end

    def self.included(base)
      OmniEvent.strategies << base
      base.extend ClassMethods
    end

    # Class methods for Strategy
    module ClassMethods
      # Returns an inherited set of default options set at the class-level
      # for each strategy.
      def default_options
        existing = superclass.respond_to?(:default_options) ? superclass.default_options : {}
        @default_options ||= OmniEvent::Strategy::Options.new(existing)
      end

      # This allows for more declarative subclassing of strategies by allowing
      # default options to be set using a simple configure call.
      #
      # @param options [Hash] If supplied, these will be the default options
      #    (deep-merged into the superclass's default options).
      # @yield [Options] The options Mash that allows you to set your defaults as you'd like.
      #
      # @example Using a yield to configure the default options.
      #
      #   class MyStrategy
      #     include OmniEvent::Strategy
      #
      #     configure do |c|
      #       c.foo = 'bar'
      #     end
      #   end
      #
      # @example Using a hash to configure the default options.
      #
      #   class MyStrategy
      #     include OmniEvent::Strategy
      #     configure foo: 'bar'
      #   end
      def configure(options = nil)
        if block_given?
          yield default_options
        else
          default_options.deep_merge!(options)
        end
      end

      # Directly declare a default option for your class. This is a useful from
      # a documentation perspective as it provides a simple line-by-line analysis
      # of the kinds of options your strategy provides by default.
      #
      # @param name [Symbol] The key of the default option in your configuration hash.
      # @param value [Object] The value your object defaults to. Nil if not provided.
      #
      # @example
      #
      #   class MyStrategy
      #     include OmniEvent::Strategy
      #
      #     option :foo, 'bar'
      #     option
      #   end
      def option(name, value = nil)
        default_options[name] = value
      end

      # Sets (and retrieves) option key names for initializer arguments to be
      # recorded as. This takes care of 90% of the use cases for overriding
      # the initializer in OmniEvent Strategies.
      def args(args = nil)
        if args
          @args = Array(args)
          return
        end
        existing = superclass.respond_to?(:args) ? superclass.args : []
        (instance_variable_defined?(:@args) && @args) || existing
      end
    end

    attr_reader :options

    # Initializes the strategy. An `options` hash is automatically
    # created from the last argument if it is a hash.
    #
    # @overload new(options = {})
    #   If nothing but a hash is supplied, initialized with the supplied options
    #   overriding the strategy's default options via a deep merge.
    # @overload new(*args, options = {})
    #   If the strategy has supplied custom arguments that it accepts, they may
    #   will be passed through and set to the appropriate values.
    #
    # @yield [Options] Yields options to block for further configuration.
    def initialize(*args, &block) # rubocop:disable Lint/UnusedMethodArgument
      @options = self.class.default_options.dup

      options.deep_merge!(args.pop) if args.last.is_a?(Hash)
      options[:name] ||= self.class.to_s.split("::").last.downcase

      self.class.args.each do |arg|
        break if args.empty?

        options[arg] = args.shift
      end

      # Make sure that all of the args have been dealt with, otherwise error out.
      raise ArgumentError, "Received wrong number of arguments. #{args.inspect}" unless args.empty?

      yield options if block_given?
    end

    def request(method, opts)
      options.deep_merge!(opts)

      authorize
      return unless @token

      send(method)
    end

    def authorize
      @token = options[:token]
    end

    def event
      raise NotImplementedError
    end

    def event_list
      raise NotImplementedError
    end

    # Direct access to the OmniEvent logger, automatically prefixed
    # with this strategy's name.
    #
    # @example
    #   log :warn, 'This is a warning.'
    def log(level, message)
      OmniEvent.logger.send(level, "(#{name}) #{message}")
    end

    def name
      options[:name]
    end
  end
end
