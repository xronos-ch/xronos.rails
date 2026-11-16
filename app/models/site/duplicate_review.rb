# frozen_string_literal: true

class Site
  # Reviews site pairs that share at least one radiocarbon measurement key.
  class DuplicateReview
    FIELD_GROUPS = { 'name' => [:name], 'coordinates' => %i[lat lng], 'country' => [:country_code] }.freeze

    class InvalidSelection < StandardError; end
    class StaleReview < StandardError; end
    class ContextConfirmationRequired < StandardError; end
    class LinkedResourceConflict < StandardError; end

    attr_reader :sites

    def self.pairs(site_ids = nil)
      sql = <<~SQL
        WITH measurement_sites AS (#{measurement_keys(site_ids).to_sql})
        SELECT left_site.site_id AS first_id, right_site.site_id AS second_id, COUNT(*) AS evidence_count
        FROM measurement_sites left_site
        JOIN measurement_sites right_site ON right_site.site_id > left_site.site_id
          AND (right_site.lab_identifier, right_site.bp, right_site.std) =
              (left_site.lab_identifier, left_site.bp, left_site.std)
        GROUP BY left_site.site_id, right_site.site_id
      SQL
      Site.unscoped.from("(#{sql}) AS sites")
    end

    def self.review_queue
      pairs.order(Arel.sql('evidence_count DESC, first_id, second_id'))
    end

    def self.measurement_keys(site_ids)
      measurements = C14.joins(sample: { context: :site })
                        .where.not(c14s: { lab_identifier: [nil, ''] })
                        .where.not(bp: nil).where.not(std: nil)
      measurements = measurements.where(sites: { id: site_ids }) if site_ids
      measurements.select('sites.id AS site_id', :lab_identifier, :bp, :std).distinct
    end
    private_class_method :measurement_keys

    def initialize(sites)
      @sites = sites.uniq.sort_by(&:id)
      raise InvalidSelection unless @sites.size == 2
    end

    def evidence
      @evidence ||= begin
        pair = self.class.pairs(sites.map(&:id)).take
        raise ActiveRecord::RecordNotFound unless pair

        pair.evidence_count
      end
    end

    def measurement_comparison
      @measurement_comparison ||= DuplicateMeasurements.new(sites)
    end

    def impact(site)
      @impacts ||= {}
      @impacts[site.id] ||= {
        contexts: site.contexts.reorder(:id).pluck(:id, :name),
        c14s: site.c14s.count,
        typos: site.typos.count
      }
    end

    def context_measurement_counts
      ids = sites.flat_map { |site| impact(site).fetch(:contexts).map(&:first) }
      C14.joins(:sample).where(samples: { context_id: ids }).group('samples.context_id').count
    end

    def collisions
      first, second = sites
      first_names = impact(first).fetch(:contexts).to_h.values
      second_names = impact(second).fetch(:contexts).to_h.values
      first_names & second_names
    end

    def linked_resource_conflicts
      first, second = sites.map { |site| site.linked_resources.pluck(:source, :external_id).to_h }
      (first.keys & second.keys).reject { |source| first[source] == second[source] }
    end

    def fingerprint
      payload = sites.map { |site| [site.cache_key_with_version, impact(site)] }
      Digest::SHA256.hexdigest(payload.to_json)
    end

    def apply!(target_id:, sources:, keep_names:, fingerprint:, confirm_contexts:, custom_values: {}, separate_contexts: [])
      Site.transaction do
        current = self.class.new(Site.where(id: sites.map(&:id)).order(:id).lock.to_a)
        current.evidence
        raise StaleReview unless current.fingerprint == fingerprint && !superseded_pair?

        current.merge!(target_id, sources, keep_names, confirm_contexts, CustomDuplicateValues.new(custom_values),
                       separate_contexts)
      end
    end

    protected

    def merge!(target_id, sources, keep_names, confirm_contexts, custom_values, separate_contexts)
      target = find_site(target_id)
      original_names = sites.map(&:name).compact_blank.uniq
      attributes = selected_attributes(sources, custom_values)
      source = (sites - [target]).sole
      validate_linked_resources!
      resolve_contexts!(source, confirm_contexts, separate_contexts)
      source.merge_into!(target)
      target.update_for_duplicate_merge!(attributes) if attributes.any?
      retain_names!(target, original_names) if keep_names
      target
    end

    private

    def validate_linked_resources!
      return if linked_resource_conflicts.empty?

      raise LinkedResourceConflict, 'Resolve the conflicting linked resources before merging.'
    end

    def resolve_contexts!(source, confirm_contexts, separate_contexts)
      choices = DuplicateContextChoices.new(sites: sites, source: source, collisions: collisions)
      renames = choices.renames(separate_contexts)
      if collisions.size > renames.size && !confirm_contexts
        raise ContextConfirmationRequired, 'Name the contexts you want to keep separate or select “Also merge the listed contexts without a new name”.'
      end

      renames.each { |id, name| source.contexts.find(id).update!(name: name) }
    end

    def superseded_pair?
      Supersession.exists?(superseded_type: 'Site', superseded_id: sites.map(&:id))
    end

    def find_site(id)
      sites.find { |site| site.id.to_s == id.to_s } || raise(InvalidSelection)
    end

    def selected_attributes(sources, custom_values)
      sources.each_with_object({}) do |(field, id), attributes|
        next if id.blank?

        attributes.merge!(id == 'custom' ? custom_values.attributes_for(field) : attributes_from_site(field, id))
      end
    end

    def attributes_from_site(field, id)
      site = find_site(id)
      group = FIELD_GROUPS[field] || raise(InvalidSelection)
      group.index_with { |attribute| site.public_send(attribute) }
    end

    def retain_names!(target, names)
      (names - [target.name] - target.site_names.pluck(:name)).each do |name|
        target.site_names.create!(name: name)
      end
    end
  end
end
