# frozen_string_literal: true

class Site
  # Allows the curator to keep colliding contexts separate by naming the source context.
  class DuplicateContextChoices
    class InvalidName < StandardError; end

    def initialize(sites:, source:, collisions:)
      @sites = sites
      @source = source
      @collisions = collisions
    end

    def renames(choices)
      requested = choices.filter_map do |choice|
        name = choice.fetch('name', '').strip
        [choice['context_id'], name] if name.present?
      end
      return {} if requested.empty?

      candidates = source_by_first_context_id
      reserved_names = Context.where(site: @sites).pluck(:name).to_set
      requested.each_with_object({}) do |(first_id, name), changes|
        source_id = candidates[first_id.to_s]
        unless source_id && !changes.key?(source_id) && reserved_names.add?(name)
          raise InvalidName, 'Enter a distinct new name for each source context you want to keep separate.'
        end

        changes[source_id] = name
      end
    end

    private

    def source_by_first_context_id
      first_by_name = @sites.first.contexts.where(name: @collisions).pluck(:name, :id).to_h
      @source.contexts.where(name: @collisions).pluck(:name, :id).to_h
             .transform_keys { |name| first_by_name.fetch(name).to_s }
    end
  end
end
