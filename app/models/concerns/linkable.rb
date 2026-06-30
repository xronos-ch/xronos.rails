module Linkable

  extend ActiveSupport::Concern

  class_methods do
    # Declare which linked resource sources this model can be linked to.
    # For each source key (e.g. :wikidata), linkable_to generates:
    #
    #   <source>_link          - reader that returns the LinkedResource, or nil
    #   missing_<source>_link? - predicate true if no link of this source exists
    #   pending_<source>_link? - predicate true if a pending link of this source exists
    #   missing_<source>_link  - scope of records with no link of this source
    #   pending_<source>_link  - scope of records with a pending link of this source
    #
    # The two issue symbols are also registered in linked_resource_issues so
    # they appear in the curation dashboard.
    def linkable_to(*source_keys)
      source_keys.each { |key| linkable_to_source(key) }
    end

    # The complete list of issue symbols for every source declared via
    # linkable_to on this class.
    def linked_resource_issues
      @linked_resource_issues ||= []
    end

    private

    # Orchestrates the per-source generation in a readable order.
    def linkable_to_source(key)
      source = source_for(key)
      define_link_reader(key, source)
      define_link_predicates(key)
      define_link_scopes(key, source)
      register_link_issues(key)
    end

    def source_for(key)
      source = LinkedResource::Source.find(key)
      raise "Unknown linked resource source: #{key}" if source.nil?
      source
    end

    def define_link_reader(key, source)
      define_method("#{key}_link") { linked_resources.find_by(source: source.name) }
    end

    def define_link_predicates(key)
      define_method("missing_#{key}_link?") { public_send("#{key}_link").blank? }
      define_method("pending_#{key}_link?") { public_send("#{key}_link")&.status == "pending" }
    end

    def define_link_scopes(key, source)
      scope "missing_#{key}_link".to_sym, -> {
        where.not(id: LinkedResource.where(linkable_type: name, source: source.name).select(:linkable_id).distinct)
      }
      scope "pending_#{key}_link".to_sym, -> {
        joins(:linked_resources).where(linked_resources: { source: source.name, status: "pending" })
      }
    end

    def register_link_issues(key)
      @linked_resource_issues ||= []
      @linked_resource_issues << :"missing_#{key}_link"
      @linked_resource_issues << :"pending_#{key}_link"
    end
  end

  included do
    # The subset of the class's linked_resource_issues that this instance
    # currently has. Used by the curation dashboard nav and badges.
    def linked_resource_issues
      self.class.linked_resource_issues.select do |issue|
        has_linked_resource_issue?(issue)
      end
    end

    def has_linked_resource_issue?(issue)
      send("#{issue}?")
    end
  end

end
