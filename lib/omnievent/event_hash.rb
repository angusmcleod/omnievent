# frozen_string_literal: true

module OmniEvent
  # The EventHash is a normalized schema returned by all OmniEvent strategies.
  class EventHash < OmniEvent::KeyStore
    def self.subkey_class
      Hashie::Mash
    end

    # Tells you if this is considered to be a valid EventHash.
    def valid?
      provider? &&
        data? &&
        data.valid? &&
        (!metadata || metadata.valid?) &&
        (!associated_data || associated_data.valid?)
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
      def permitted?(keys, attribute = nil, sub_attribute = nil)
        permitted = self.class.permitted_attributes
        permitted = permitted[attribute] if attribute
        permitted = permitted[sub_attribute] if sub_attribute
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
          return true if value.to_s.empty? || send("#{attribute}_valid?")

          invalid << attribute
          false
        end
      end

      def invalid
        @invalid ||= []
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
          name
          description
          url
        ]
      end

      def self.required_attributes
        %w[
          start_time
          name
        ]
      end

      def start_time_valid?
        OmniEvent::Utils.valid_time?(start_time)
      end

      def end_time_valid?
        OmniEvent::Utils.valid_time?(end_time)
      end

      def name_valid?
        OmniEvent::Utils.valid_type?(name, :string)
      end

      def description_valid?
        OmniEvent::Utils.valid_type?(name, :string)
      end

      def url_valid?
        OmniEvent::Utils.valid_url?(url)
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
          uid
          created_at
          updated_at
          language
          status
          taxonomies
        ]
      end

      def self.permitted_statuses
        %w[
          draft
          published
          cancelled
        ]
      end

      def uid_valid?
        OmniEvent::Utils.valid_uid?(uid)
      end

      def created_at_valid?
        OmniEvent::Utils.valid_time?(created_at)
      end

      def updated_at_valid?
        OmniEvent::Utils.valid_time?(updated_at)
      end

      def language_valid?
        OmniEvent::Utils.valid_language_code?(language)
      end

      def status_valid?
        self.class.permitted_statuses.include?(status)
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
          location: %w[uid name address city postal_code country latitude longitude url],
          virtual_location: { "uid": "", "entry_points": %w[uri type code label] },
          organizer: %w[uid name email uris],
          registrations: %w[uid name email status]
        }
      end

      def self.permitted_entry_point_attributes
        %w[
          uri
          type
          code
          label
        ]
      end

      def location_valid?
        return true unless location
        return false unless location.is_a?(Hash)
        return false unless permitted?(location.keys, :location)

        location.all? do |key, value|
          case key
          when "uid"
            OmniEvent::Utils.valid_uid?(value)
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
        return true unless virtual_location
        return false unless virtual_location.is_a?(Hash)
        return true unless virtual_location["entry_points"]

        return false if virtual_location["uid"] && !OmniEvent::Utils.valid_uid?(virtual_location["uid"])

        virtual_location["entry_points"].all? do |entry_point|
          return false unless entry_point.is_a?(Hash)
          return false unless entry_point["uri"] && entry_point["type"]
          return false unless permitted?(entry_point.keys, :virtual_location, :entry_points)
          return false unless case entry_point["type"]
                              when "video"
                                OmniEvent::Utils.valid_url?(entry_point["uri"])
                              when "phone", "sip"
                                OmniEvent::Utils.valid_type?(entry_point["uri"], :string)
                              else
                                false
                              end

          OmniEvent::Utils.valid_type?(entry_point["label"], :string) &&
            OmniEvent::Utils.valid_type?(entry_point["code"], :string)
        end
      end

      def organizer_valid?
        return true unless organizer
        return false unless organizer.is_a?(Hash)
        return false unless permitted?(organizer.keys, :organizer)

        organizer.all? do |key, value|
          case key
          when "uid"
            OmniEvent::Utils.valid_uid?(value)
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

      def self.permitted_registration_statuses
        %w[
          confirmed
          declined
          tentative
        ]
      end

      def registrations_valid?
        return true unless registrations
        return false unless registrations.is_a?(Array)

        registrations.all? do |registration|
          return false unless registration.is_a?(Hash)
          return false unless registration["email"] && registration["status"]
          return false unless permitted?(registration.keys, :registrations)

          registration.all? do |key, value|
            case key
            when "uid"
              OmniEvent::Utils.valid_uid?(value)
            when "name"
              OmniEvent::Utils.valid_type?(value, :string)
            when "email"
              OmniEvent::Utils.valid_email?(value)
            when "status"
              self.class.permitted_registration_statuses.include?(value)
            else
              false
            end
          end
        end
      end
    end
  end
end
