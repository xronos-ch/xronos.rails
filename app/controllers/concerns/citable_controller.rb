module CitableController
  extend ActiveSupport::Concern

  def show
    respond_to do |format|
      format.html   { redirect_to citable_record_path(anchor: citation_anchor) }
      format.bibtex { send_data citable_record.format_bibtex, download_options("bib", "application/x-bibtex") }
      format.json   { send_data citable_record.format_json,   download_options("json", "application/json") }
      format.yaml   { send_data citable_record.format_yaml,   download_options("yaml", "text/yaml") }
      format.ris    { send_data citable_record.format_ris,    download_options("ris",  "application/x-research-info-systems") }
    end
  end

  private

  def download_options(extension, mime)
    base = "#{citable_record.model_name.singular}_#{citable_record.id}"
    { type: "#{mime}; charset=utf-8", filename: "#{base}.#{extension}", disposition: "attachment" }
  end

  # Polymorphic path to the parent record's show page.
  def citable_record_path(opts = {})
    polymorphic_path(citable_record, **opts)
  end

  # Section anchor on the show page. Defaults to "<model>-citation",
  # matching the existing pattern in show views.
  def citation_anchor
    "#{citable_record.model_name.singular}-citation"
  end
end
