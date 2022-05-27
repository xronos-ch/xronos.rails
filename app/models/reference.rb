class Reference < ApplicationRecord
  default_scope { order(:short_ref) }

  has_paper_trail
  
  validates :short_ref, presence: true
  has_many :citations, dependent: :destroy

  def render
    return short_ref if bibtex.blank?
    return short_ref if parsed.blank?

    cp = CiteProc::Processor.new style: 'apa', format: 'html', locale: 'en'
    cp.import parsed.to_citeproc

    html = parsed['@entry, @meta_content'].map do |e|
      cp.render :bibliography, id: e.key
    end
    html.join.html_safe
  end

  def render_citation
    return short_ref if bibtex.blank?
    return short_ref if parsed.blank?
    
    cp = CiteProc::Processor.new style: 'chicago-author-date', format: 'html', locale: 'en'
    cp.import parsed.to_citeproc

    html = parsed['@entry, @meta_content'].map do |e|
      cp.render :citation, id: e.key
    end
    html.join.delete('()').html_safe
  end

  private

  def parsed
    BibTeX.parse bibtex, filter: :latex
  end

end
