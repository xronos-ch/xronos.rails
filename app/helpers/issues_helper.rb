module IssuesHelper
  def issue_label(issue)
    case issue
    when :missing_taxon
      "MISSING_TAXON"
    when :unknown_taxon
      "UNKNOWN_TAXON"
    end
  end

  def issue_description(issue)
    case issue
    when :missing_taxon
      "Taxonomic classification of the sample material is unknown"
    when :unknown_taxon
      "Taxon not matched to the GBIF Backbone Taxonomy"
    end
  end

  def issue_badge(issue)
    content_tag :span, title: issue_description(issue), class: "badge text-bg-warning" do
      issue_label(issue)
    end
  end
end
