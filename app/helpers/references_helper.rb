##
# Presentation of bibliographic (CSL) data
module ReferencesHelper
  # Preferred order of CSL fields in the structured view of a reference's
  # bibliographic data; any other fields follow in alphabetical order
  CSL_FIELD_ORDER = %w[
    type author editor translator title container-title issued volume issue
    page publisher publisher-place edition DOI URL note
  ].freeze

  CSL_FIELD_LABELS = {
    "DOI" => "DOI",
    "URL" => "URL",
    "ISBN" => "ISBN",
    "ISSN" => "ISSN"
  }.freeze

  # Fields of a CSL item to display: everything except the internal "id"
  # and "_"-prefixed QA keys, in CSL_FIELD_ORDER then alphabetical order
  def csl_display_fields(item)
    keys = item.keys.reject { |key| key == "id" || key.start_with?("_") }
    (CSL_FIELD_ORDER & keys) + (keys - CSL_FIELD_ORDER).sort
  end

  def csl_field_label(key)
    CSL_FIELD_LABELS.fetch(key) { key.tr("-", " ").humanize }
  end

  # Formats a CSL field value for display. Names and dates are detected by
  # the shape of the data, so any CSL field is handled.
  def csl_field_value(key, value)
    if csl_names?(value)
      safe_join(value.map { |name| csl_name(name) }, "; ")
    elsif value.is_a?(Hash)
      csl_date(value) || value.to_s
    elsif value.is_a?(Array)
      safe_join(value.map { |element| csl_field_value(key, element) }, "; ")
    elsif %w[DOI URL].include?(key)
      csl_link(key, value)
    else
      value.to_s
    end
  end

  private

  def csl_names?(value)
    value.is_a?(Array) && value.any? &&
      value.all? { |element| element.is_a?(Hash) && (element.key?("family") || element.key?("literal")) }
  end

  def csl_name(name)
    return ERB::Util.html_escape(name["literal"]) if name.key?("literal")

    ERB::Util.html_escape([ name["family"], name["given"] ].compact.join(", "))
  end

  def csl_date(value)
    if value["date-parts"].present?
      value["date-parts"].map { |parts| csl_date_parts(parts) }.join("–")
    elsif value["literal"].present? || value["raw"].present?
      value["literal"] || value["raw"]
    end
  end

  def csl_date_parts(parts)
    parts.map.with_index { |part, i| i.zero? ? part.to_s : part.to_s.rjust(2, "0") }.join("-")
  end

  def csl_link(key, value)
    url = value.to_s
    url = "https://doi.org/#{url}" if key == "DOI" && !url.start_with?("http")
    link_to(value.to_s, url)
  end
end
