# frozen_string_literal: true

# == Schema Information
#
# Table name: sites
# Database name: primary
#
#  id           :bigint           not null, primary key
#  country_code :string
#  lat          :decimal(, )
#  lng          :decimal(, )
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_sites_on_country_code  (country_code)
#  index_sites_on_name          (name)
#

class Site < ApplicationRecord
  include Versioned
  include Supersedable
  include BatchMatchableToWikidata
  include Mergeable

  exact_duplicates_on :name,
                      lat: :nil_matches_nil,
                      lng: :nil_matches_nil,
                      country_code: :nil_matches_nil

  # Children
  has_many :site_names, dependent: :destroy
  has_many :contexts
  destroy_async_with_paper_trail :contexts
  has_many :citations, as: :citing, dependent: :destroy_async

  # Grandchildren
  has_many :samples, through: :contexts
  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts
  has_many :references, through: :citations

  # Cousins
  has_and_belongs_to_many :site_types, optional: true

  has_many :linked_resources, as: :linkable, dependent: :destroy
  has_many :functional_classifications, as: :assignable, dependent: :destroy

  composed_of :coordinates,
              mapping: [%w[lng longitude], %w[lat latitude]],
              allow_nil: true,
              constructor: lambda { |lng, lat|
                # only build Coordinates if we have both values
                Coordinates.new(lng, lat) if lng.present? && lat.present?
              }

  validates :name, presence: true

  accepts_nested_attributes_for :site_names,
                                reject_if: :all_blank, allow_destroy: true

  include Duplicable
  potential_duplicates_on :name, :lat, :lng, :country_code

  after_save :merge_exact_duplicates
  validate :no_exact_duplicate, on: :create

  before_merge :reassign_contexts!
  before_merge :reassign_site_names!
  before_merge :reassign_citations!
  before_merge :reassign_linked_resources!
  before_merge :reassign_site_types!
  before_merge :reassign_functional_classifications!

  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = %i[missing_coordinates invalid_coordinates missing_country_code]

  include Linkable
  linkable_to :wikidata
  linkable_to :pleiades
  linkable_to :vici
  linkable_to :opencontext
  linkable_to :idai_gazetteer

  include PgSearch::Model
  pg_search_scope :search,
                  against: :name,
                  using: { tsearch: { prefix: true } } # match partial words
  multisearchable against: :name

  scope :with_counts, lambda {
    select <<~SQL
      sites.*,
      (
        SELECT COUNT(c14s.id)#{' '}
        FROM c14s
        JOIN samples ON samples.id = c14s.sample_id
        JOIN contexts ON contexts.id = samples.context_id
        WHERE contexts.site_id = sites.id
      ) AS c14s_count,
      (
        SELECT COUNT(typos.id)#{' '}
        FROM typos
        JOIN samples ON samples.id = typos.sample_id
        JOIN contexts ON contexts.id = samples.context_id
        WHERE contexts.site_id = sites.id
      ) AS typos_count
    SQL
  }

  def self.label
    'Site'
  end

  def label
    name
  end

  def self.icon
    'icons/site.svg'
  end

  def country
    return nil if country_code.blank?

    ISO3166::Country[country_code] ||
      ISO3166::Country.find_country_by_any_name(country_code)
  end

  def country_from_coordinates
    return nil if lat.blank? || lng.blank?

    result = Geocoder.search([lat, lng]).first
    return ISO3166::Country[result.country_code] if result && result.country_code.present?

    nil
  end

  def country_code_from_coordinates
    return nil if lat.blank? || lng.blank?

    result = Geocoder.search([lat, lng]).first
    return result.country_code.upcase if result && result.country_code.present?

    nil
  end

  def n_c14s
    c14s.count
  end

  def n_typos
    typos.count
  end

  def recursive_references
    site_reference_scope = Reference
                           .joins(:citations)
                           .where(citations: { citing_type: 'Site', citing_id: id })

    c14_reference_scope = Reference
                          .joins(:citations)
                          .where(citations: { citing_type: 'C14', citing_id: c14s.select(:id) })

    site_reference_scope.or(c14_reference_scope).distinct.to_a
  end

  def default_c14_curve
    return :IntCal20 unless lat.present?

    # TODO: what about the sea?
    # https://github.com/xronos-ch/xronos.rails/issues/326
    if lat >= 0
      :IntCal20
    else
      :SHCal20
    end
  end

  # Issues
  scope :missing_coordinates, -> { where('lat IS NULL OR lng IS NULL') }
  def missing_coordinates?
    lat.blank? or lng.blank?
  end

  scope :invalid_coordinates, -> { where('lat > 90 OR lat < -90 OR lng > 180 OR lng < -180') }
  def invalid_coordinates?
    return if missing_coordinates?

    coordinates.invalid_latitude? or coordinates.invalid_longitude?
  end

  scope :missing_country_code, -> { where("country_code = '' OR country_code IS NULL") }
  def missing_country_code?
    country_code.blank?
  end

  def find_exact_duplicate
    candidate = duplicates_except.first
    return nil unless candidate

    linked_resources_compatible?(candidate) ? candidate : nil
  end

  private

  def linked_resources_compatible?(other)
    my_links    = linked_resources.pluck(:source, :external_id).to_h
    their_links = other.linked_resources.pluck(:source, :external_id).to_h

    my_links.all? do |source, external_id|
      their_links[source].nil? || their_links[source] == external_id
    end
  end

  # When two sites are merged, contexts that share a name under both
  # sites are explicitly merged via the Context Mergeable framework,
  # preserving all chronological data (samples, C14s, typos, FNs).
  # The remaining (non-colliding) contexts are then moved to the
  # canonical site.
  def reassign_contexts!
    return if merged_into_id.blank?

    from_id = id
    to_id   = merged_into_id

    merge_colliding_contexts(from_id, to_id)
    merge_nil_name_contexts(from_id, to_id)
    Context.where(site_id: from_id).update_all(site_id: to_id)
  end

  # When two sites are merged, contexts that share a name under both
  # sites are explicitly merged via the Context Mergeable framework,
  # preserving all chronological data (samples, C14s, typos, FNs).
  def merge_colliding_contexts(from_id, to_id)
    Context.where(site_id: to_id).where.not(name: nil).pluck(:name).each do |name|
      dupe_context = Context.find_by(site_id: from_id, name: name)
      next unless dupe_context

      canonical_context = Context.find_by(site_id: to_id, name: name)
      dupe_context.merge_into!(canonical_context)
    end
  end

  # Handle nil-name contexts (the :nil_matches_nil case for Context's key).
  def merge_nil_name_contexts(from_id, to_id)
    return unless Context.where(site_id: from_id, name: nil).exists? &&
                  Context.where(site_id: to_id,   name: nil).exists?

    nil_contexts = Context.where(name: nil, site_id: [from_id, to_id]).order(:created_at, :id).to_a
    nil_contexts[1..].each { |dupe| dupe.merge_into!(nil_contexts.first) }
  end

  def reassign_site_names!
    SiteName.where(site_id: id).update_all(site_id: merged_into_id)
  end

  def reassign_citations!
    Citation.reassign_all_to!(from: self, to: canonical)
  end

  def reassign_linked_resources!
    LinkedResource.reassign_all_to!(from: self, to: canonical)
  end

  def reassign_site_types!
    canonical_site = canonical
    existing_ids = canonical_site.site_types.pluck(:id)
    site_types.where.not(id: existing_ids).find_each do |site_type|
      canonical_site.site_types << site_type
    end
    site_types.clear
  end

  def reassign_functional_classifications!
    FunctionalClassification.reassign_all_to!(from: self, to: canonical)
  end
end
