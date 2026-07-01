class LinkedResource
  class Source
    attr_reader :key, :name, :url_template, :id_pattern, :icon, :description

    def initialize(key:, name:, url_template:, id_pattern: nil, icon: nil, description: nil, has_logo: true)
      @key = key.to_sym
      @name = name
      @url_template = url_template
      @id_pattern = id_pattern
      @icon = icon
      @description = description
      @has_logo = has_logo
    end

    # True if the source has a logo SVG at
    # `app/assets/images/simple_icons/<icon>.svg`. False if the source
    # uses a fallback icon (e.g. the first letter of its name in a
    # Bootstrap Icons circle). 
    def has_logo?
      @has_logo
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
