module IssuesHelper
  def issue_label(issue)
    issue.to_s.upcase
  end

  def issue_description(issue)
    case issue
    # C14s
    when :missing_c14_age
      "Radiocarbon date with no age value"
    when :very_old_c14
      "Radiocarbon date with an age greater than 50000 uncal BP"
    when :missing_c14_error
      "Radiocarbon date with no error associated with age value"
    when :missing_d13c
      "Radiocarbon date with no δ13C value"
    when :missing_d13c_error
      "Radiocarbon date with no error associated with δ13C value"
    when :missing_c14_method
      "Method used to obtain radiocarbon measurement (e.g. conventional, AMS) is not recorded"
    when :missing_c14_lab_id
      "No laboratory identifier recorded for radiocarbon date"
    when :invalid_lab_id
      "Laboratory identifier doesn't match the conventional format (e.g. Lab-1234)"
    when :missing_c14_lab
      "No radiocarbon laboratory associated with radiocarbon date"
    # References
    when :mixed_reference
      "Reference potentially combines multiple sources"
    when :missing_bibtex
      "No bibliographical information recorded"
    # Samples
    when :missing_material
      "Sample material is not recorded"
    when :missing_taxon
      "Taxonomic classification of the sample material is not recoreded"
    when :missing_crs
      "Coordinate reference system (CRS) of sample coordinates is not recorded"
    # Sites
    when :missing_coordinates
      "At least one geographic coordinate is not recorded"
    when :invalid_coordinates
      "At least one geographic coordinate is not valid"
    when :missing_country_code
      "Country is not recorded"
    # Taxons
    when :unknown_taxon
      "Taxon not matched to the GBIF Backbone Taxonomy"
    when :long_taxon
      "Name of taxon is longer than 64 characters"
    else
      ""
    end
  end

  def issue_badge(issue)
    content_tag :span, title: issue_description(issue), class: "badge text-bg-warning" do
      issue_label(issue)
    end
  end
end
