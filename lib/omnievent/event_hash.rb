# frozen_string_literal: true

module OmniEvent
  # The EventHash is a normalized schema returned by all OmniEvent strategies.
  class EventHash < OmniEvent::KeyStore
    def self.subkey_class
      Hashie::Mash
    end

    # Tells you if this is considered to be a valid EventHash.
    def valid?
      provider? && data? && data.valid? && metadata.valid? && associated_data.valid?
    end

    def regular_writer(key, value)
      value = DataHash.new(value) if key.to_s == "data" && value.is_a?(::Hash) && !value.is_a?(DataHash)
      value = MetadataHash.new(value) if key.to_s == "metadata" && value.is_a?(::Hash) && !value.is_a?(MetadataHash)
      if key.to_s == "associated_data" && value.is_a?(::Hash) && !value.is_a?(AssociatedDataHash)
        value = AssociatedDataHash.new(value)
      end
      super
    end

    # Base for data hashes
    class EventHashBase < OmniEvent::KeyStore
      def permitted?(keys, attribute = nil)
        permitted = self.class.permitted_attributes
        permitted = attribute ? permitted[attribute] : permitted
        permitted = permitted.is_a?(Hash) ? permitted.keys.map(&:to_s) : permitted
        (keys - permitted).empty?
      end

      # Tells you if this is considered to be a valid hash.
      def valid?
        if self.class.respond_to?(:required_attributes) && !self.class.required_attributes.all? do |attribute|
             value = send(attribute)
             !value.nil? && !value.empty?
           end
          # All required attributes have values
          return false
        end

        # All attributes are permitted
        return false unless permitted?(keys)

        # All attribute values are valid
        self.class.permitted_attributes.all? do |attribute|
          value = send(attribute.to_s)
          !value || send("#{attribute}_valid?")
        end
      end
    end

    # The event data.
    class DataHash < EventHashBase
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
    end

    # The event metadata.
    class MetadataHash < EventHashBase
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
        OmniEvent::Utils.valid_language_code?(locale)
      end

      def taxonomies_valid?
        OmniEvent::Utils.all_valid_type?(taxonomies, :string)
      end
    end

    # The event's associated data.
    class AssociatedDataHash < EventHashBase
      def self.subkey_class
        Hashie::Mash
      end

      # The permitted MetadataHash attributes.
      def self.permitted_attributes
        {
          location: %w[name address city postal_code country latitude longitude url],
          virtual_locations: %w[uri type code label],
          organizer: %w[name email uris],
          registrations: %w[]
        }
      end

      def location_valid?
        return true unless location
        return false unless location.is_a?(Hash)
        return false unless permitted?(location.keys, :location)

        location.all? do |key, value|
          case key
          when "name", "address", "city", "postal_code"
            OmniEvent::Utils.valid_type?(value, :string)
          when "country"
            OmniEvent::Utils.valid_country_code?(value)
          when "latitude", "longitude"
            OmniEvent::Utils.valid_coordinate?(value, key.to_sym)
          when "url"
            OmniEvent::Utils.valid_url?(value)
          else
            false
          end
        end
      end

      def virtual_location_valid?
        return true unless virtual_locations
        return false unless virtual_locations.is_a?(Array)

        virtual_locations.all? do |virtual_location|
          return false unless virtual_location["uri"] && virtual_location["type"]
          return false unless permitted?(virtual_location.keys, :virtual_locations)

          return false unless case virtual_location["type"]
                              when "video"
                                OmniEvent::Utils.valid_url?(virtual_location["uri"])
                              when "phone", "sip"
                                OmniEvent::Utils.valid_type?(virtual_location["uri"], :string)
                              else
                                false
                              end

          OmniEvent::Utils.valid_type?(virtual_location["label"], :string) &&
            OmniEvent::Utils.valid_type?(virtual_location["code"], :string)
        end
      end

      def organizer_valid?
        return true unless organizer
        return false unless organizer.is_a?(Hash)
        return false unless permitted?(organizer.keys, :organizer)

        organizer.all? do |key, value|
          case key
          when "name"
            OmniEvent::Utils.valid_type?(value, :string)
          when "email"
            OmniEvent::Utils.valid_email?(value)
          when "uris"
            OmniEvent::Utils.all_valid_type?(value, :string)
          else
            false
          end
        end
      end
    end
  end
end
