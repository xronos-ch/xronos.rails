class Reference < ApplicationRecord
  default_scope { order(:short_ref) }

  has_paper_trail
  
  validates :short_ref, presence: true
  has_many :citations, dependent: :destroy

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
