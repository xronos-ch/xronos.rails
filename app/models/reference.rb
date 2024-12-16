# == Schema Information
#
# Table name: references
#
#  id         :bigint           not null, primary key
#  bibtex     :text
#  short_ref  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_references_on_short_ref  (short_ref)
#
class Reference < ApplicationRecord
  DELIM_PATTERN = '[;,]'

  has_many :citations, dependent: :destroy

  has_many :sites, :through => :citations, :source => :citing, :source_type => 'Site'
  has_many :c14s, :through => :citations, :source => :citing, :source_type => 'C14'
  has_many :typos, :through => :citations, :source => :citing, :source_type => 'Typo'
  has_many :dendros, :through => :citations, :source => :citing, :source_type => 'Dendro'


  validates :short_ref, presence: true

  include Versioned
  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = [ :mixed_reference, :missing_bibtex ]

  include PgSearch::Model
  pg_search_scope :search, 
    against: [ :short_ref, :bibtex ],
    using: { tsearch: { prefix: true } } # match partial words
  multisearchable against: [ :short_ref, :bibtex ]

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

  def anchor
    if short_ref.blank?
      return ""
    end

    "ref-" + CGI.escape(short_ref)
  end

  def format_bibtex
    parse.to_s
  end

  def format_yaml
    parse.to_yaml
  end

  def format_json
    parse.to_json
  end

  def render
    return "No bibliographic information available." if parse.blank?

    cp = CiteProc::Processor.new style: 'apa', format: 'html', locale: 'en'
    cp.import parse.to_citeproc

    html = parse['@entry, @meta_content'].map do |e|
      cp.render :bibliography, id: e.key
    end
    html.join.html_safe
  end

  def render_citation
    return short_ref if parse.blank?

    cp = CiteProc::Processor.new style: 'chicago-author-date', format: 'html', locale: 'en'
    cp.import parse.to_citeproc

    html = parse['@entry, @meta_content'].map do |e|
      cp.render :citation, id: e.key
    end
    html.join.delete('()').html_safe
  end

  # Issues
  scope :mixed_reference, -> { where("short_ref ~* ?", DELIM_PATTERN) }
  def mixed_reference?
    short_ref.match?(DELIM_PATTERN)
  end
  
  scope :missing_bibtex, -> { where(bibtex: nil) }
  def missing_bibtex?
    bibtex.blank?
  end

  private

  def parse
    if bibtex.present?
      BibTeX.parse bibtex, filter: :latex
    else
      bib = BibTeX::Entry.new
      bib.type = :misc
      bib.key = short_ref
      return bib
    end
  end

end
