class BackfillReferenceCsl < ActiveRecord::Migration[8.0]
  def up
    Reference.find_each do |ref|
      csl_items = convert_bibtex_to_csl(ref)
      doi = extract_doi(csl_items)

      ref.update_columns(csl: csl_items, doi: doi)
    rescue => e
      Rails.logger.warn("Failed to convert reference #{ref.id} to CSL: #{e.message}")

      fallback = fallback_with_raw_bibtex(ref)
      ref.update_columns(csl: fallback, doi: nil)
    end
  end

  def down
    Reference.update_all(csl: nil, doi: nil)
  end

  private

  def convert_bibtex_to_csl(ref)
    if ref.bibtex.blank?
      return [{ "id" => "ref-#{ref.id}", "type" => "misc", "title" => ref.short_ref }]
    end

    parsed = BibTeX.parse(ref.bibtex, filter: :latex).to_citeproc
    return fallback_with_raw_bibtex(ref) if parsed.blank?

    parsed
  end

  def fallback_with_raw_bibtex(ref)
    [{
      "id" => "ref-#{ref.id}",
      "type" => "misc",
      "title" => ref.short_ref,
      "_raw_bibtex" => ref.bibtex
    }]
  end

  def extract_doi(csl_items)
    return nil if csl_items.blank?

    doi = csl_items.first["DOI"]
    return nil if doi.blank?

    normalize_doi(doi)
  end

  def normalize_doi(doi)
    doi.strip
       .sub(/\Ahttps?:\/\/doi\.org\//i, "")
       .sub(/\Adoi:/i, "")
       .strip
       .downcase
       .presence
  end
end
