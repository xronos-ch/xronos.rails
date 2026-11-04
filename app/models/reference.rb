# == Schema Information
#
# Table name: references
# Database name: primary
#
#  id         :bigint           not null, primary key
#  csl        :jsonb
#  doi        :string
#  searchable :tsvector
#  short_ref  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_references_on_doi         (doi)
#  index_references_on_searchable  (searchable) USING gin
#  index_references_on_short_ref   (short_ref)
#

class Reference < ApplicationRecord
  DELIM_PATTERN = '[;,]'
  MAX_SHORT_REF_LENGTH = 30

  has_many :citations, dependent: :destroy

  has_many :sites, :through => :citations, :source => :citing, :source_type => 'Site'
  has_many :c14s, :through => :citations, :source => :citing, :source_type => 'C14'
  has_many :typos, :through => :citations, :source => :citing, :source_type => 'Typo'

  has_many :sources

  validates :short_ref, presence: true

  include Versioned
  # searchable is a derived index column; exclude it from versioning
  # (must be a string: PT stringifies :skip only at has_paper_trail time)
  paper_trail_options[:skip] = ["searchable"]
  include Supersedable
  include Mergeable

  exact_duplicates_on :short_ref

  after_save :merge_exact_duplicates
  validate :no_exact_duplicate, on: :create

  before_save :extract_doi_from_csl

  before_merge :reassign_citations!
  before_merge :reassign_sources!

  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = [ :mixed_reference, :long_label ]

  include PgSearch::Model
  pg_search_scope :search,
    against: [ :short_ref, :csl ],
    using: { tsearch: { prefix: true, tsvector_column: :searchable } } # match partial words
  multisearchable against: [ :short_ref, :searchable_csl ]

  scope :with_citations_count, -> {
    select <<~SQL
      "references".*,
      (
        SELECT COUNT(citations.id)
        FROM citations
        WHERE reference_id = "references".id
      ) AS citations_count
    SQL
  }

  def self.label
    "Bibliographic reference"
  end

  def self.icon
    "icons/reference.svg"
  end

  def label
    really_short_ref
  end

  def really_short_ref
    if short_ref.length <= MAX_SHORT_REF_LENGTH
      return short_ref
    else
      trunc = MAX_SHORT_REF_LENGTH - 4
      return short_ref[0...trunc] + "..."
    end
  end

  def anchor
    if short_ref.blank?
      return ""
    end

    "ref-" + CGI.escape(short_ref)
  end

  def csl_items
    Array(csl)
  end

  def format_bibtex
    CitationJs.convert(csl_items_for_export, "bibtex")
  end

  def format_ris
    CitationJs.convert(csl_items_for_export, "ris")
  end

  def format_yaml
    csl_items.to_yaml
  end

  def format_json
    csl_items.to_json
  end

  def render
    return "No bibliographic information available." if csl_items.blank?

    cp = CiteProc::Processor.new style: 'apa', format: 'html', locale: 'en'
    cp.import csl_items

    html = csl_items.map do |item|
      cp.render :bibliography, id: item["id"]
    end
    html.join.html_safe
  end

  def render_citation
    @rendered_citation ||= begin
      return short_ref if csl_items.blank?

      cp = CiteProc::Processor.new style: 'chicago-author-date', format: 'html', locale: 'en'
      cp.import csl_items

      html = csl_items.map do |item|
        cp.render :citation, id: item["id"]
      end
      html.join.delete('()').html_safe
    end
  end

  # Issues
  scope :mixed_reference, -> { where("short_ref ~* ?", DELIM_PATTERN) }
  def mixed_reference?
    short_ref.match?(DELIM_PATTERN)
  end

  scope :long_label, -> { where("LENGTH(short_ref) > ?", MAX_SHORT_REF_LENGTH) }
  def long_label?
    return false if short_ref.blank?
    short_ref.length > MAX_SHORT_REF_LENGTH
  end

  # Tidy up unused references when citations are deleted.
  # N.B. Incompatible with destroy_async
  def destroy_if_orphaned
    if citations.count == 0
      self.revision_comment = "Deleted uncited reference"
      self.destroy
    end
  end

  private

  def extract_doi_from_csl
    doi = csl_items.filter_map { |item| item["DOI"].presence }.first
    self.doi = normalize_doi(doi)
  end

  def normalize_doi(doi)
    return nil if doi.blank?

    doi.strip
       .sub(/\Ahttps?:\/\/doi\.org\//i, "")
       .sub(/\Adoi:/i, "")
       .strip
       .downcase
       .presence
  end

  # Keys prefixed with "_" are internal (e.g. the "_raw_bibtex" QA leftovers
  # from the BibTeX backfill) and must not leak into exported formats.
  def csl_items_for_export
    csl_items.map { |item| item.reject { |key, _| key.start_with?("_") } }
  end

  # Content copied into the global multisearch index (pg_search_documents):
  # CSL values only — no keys, and no internal ("_"-prefixed) keys via
  # csl_items_for_export.
  def searchable_csl
    csl_items_for_export.flat_map { |item| csl_values(item) }.join(" ")
  end

  def csl_values(node)
    case node
    when Hash then node.flat_map { |_, value| csl_values(value) }
    when Array then node.flat_map { |value| csl_values(value) }
    else node.to_s
    end
  end

  def reassign_citations!
    Citation.reassign_all_to!(from: self, to: canonical)
  end

  def reassign_sources!
    Source.where(reference_id: id).update_all(reference_id: merged_into_id)
  end

end
