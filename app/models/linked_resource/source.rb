class LinkedResource
  class Source
    # Standard UUID regex per RFC 4122 (any version, case-insensitive).
    # Use as the `id_pattern` for any linked-resource source that exposes
    # UUID-based ids (e.g. OpenContext).
    UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

    attr_reader :key, :name, :url_template, :id_pattern, :icon, :description

    def initialize(key:, name:, url_template:, id_pattern: nil, icon: nil, description: nil)
      @key = key.to_sym
      @name = name
      @url_template = url_template
      @id_pattern = id_pattern
      @icon = icon
      @description = description
    end

    def url_for(id)
      format(url_template, id: id)
    end

    def valid_id?(id)
      id_pattern.nil? || id_pattern.match?(id.to_s)
    end

    class << self
      def registry
        @registry ||= {}
      end

      def register(key, **attrs)
        source = new(key: key, **attrs)
        registry[source.key] = source
      end

      def find(name_or_key)
        key = name_or_key.to_sym
        return registry[key] if registry.key?(key)
        registry.values.find { |s| s.name == name_or_key }
      end

      def known?(name)
        find(name).present?
      end

      def all
        registry.values
      end

      def reset!
        @registry = {}
      end
    end
  end
end
