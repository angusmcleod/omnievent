# frozen_string_literal: true

module OmniEvent
  # The EventHash is a normalized schema returned by all OmniEvent strategies.
  class EventHash < OmniEvent::KeyStore
    def self.subkey_class
      Hashie::Mash
    end

    # Tells you if this is considered to be a valid EventHash.
    def valid?
      provider? && data? && data.valid? && metadata.valid?
    end

    def regular_writer(key, value)
      value = DataHash.new(value) if key.to_s == "data" && value.is_a?(::Hash) && !value.is_a?(DataHash)
      value = MetadataHash.new(value) if key.to_s == "metadata" && value.is_a?(::Hash) && !value.is_a?(MetadataHash)
      super
    end

    # The event data.
    class DataHash < OmniEvent::KeyStore
      def self.subkey_class
        Hashie::Mash
      end

      def self.permitted_attributes
        %w[
          start_time
          end_time
          timezone
          name
          description
          status
          url
          virtual
        ]
      end

      def self.required_attributes
        %w[
          start_time
          name
        ]
      end

      def self.permitted_statuses
        %w[
          draft
          cancelled
          confirmed
        ]
      end

      def start_time_valid?
        OmniEvent::Utils.valid_time?(start_time)
      end

      def end_time_valid?
        OmniEvent::Utils.valid_time?(end_time)
      end

      def timezone_valid?
        OmniEvent::Utils.valid_timezone?(timezone)
      end

      def name_valid?
        OmniEvent::Utils.valid_type?(name, :string)
      end

      def description_valid?
        OmniEvent::Utils.valid_type?(name, :string)
      end

      def status_valid?
        self.class.permitted_statuses.include?(status)
      end

      def url_valid?
        OmniEvent::Utils.valid_url?(url)
      end

      def virtual_valid?
        OmniEvent::Utils.valid_type?(virtual, :boolean)
      end

      # Tells you if this is considered to be a valid DataHash.
      def valid?
        # All required attributes have values
        return false unless self.class.required_attributes.all? do |attribute|
          value = send(attribute)
          !value.nil? && !value.empty?
        end

        # All attributes are permitted
        return false unless (keys - self.class.permitted_attributes).empty?

        # All attribute values are valid
        self.class.permitted_attributes.all? do |attribute|
          value = send(attribute)
          !value || send("#{attribute}_valid?")
        end
      end
    end

    # The event metadata.
    class MetadataHash < OmniEvent::KeyStore
      def self.subkey_class
        Hashie::Mash
      end

      # The permitted MetadataHash attributes.
      def self.permitted_attributes
        %w[
          id
          created_at
          updated_at
          locale
          taxonomies
        ]
      end

      def id_valid?
        OmniEvent::Utils.valid_type?(id, :string)
      end

      def created_at_valid?
        OmniEvent::Utils.valid_time?(created_at)
      end

      def updated_at_valid?
        OmniEvent::Utils.valid_time?(updated_at)
      end

      def locale_valid?
        OmniEvent::Utils.valid_locale?(locale)
      end

      def taxonomies_valid?
        OmniEvent::Utils.all_valid_type?(taxonomies, :string)
      end

      # Tells you if this is considered to be a valid MetadataHash.
      def valid?
        # All attributes are permitted
        return false unless (keys - self.class.permitted_attributes).empty?

        # All attribute values are valid
        self.class.permitted_attributes.all? do |attribute|
          value = send(attribute)
          !value || send("#{attribute}_valid?")
        end
      end
    end
  end
end
