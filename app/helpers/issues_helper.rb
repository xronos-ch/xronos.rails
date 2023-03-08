module IssuesHelper
  def issue_badge(issue)
    case issue
    when "UNCONTROLLED_TAXON"
      '<span class="badge text-bg-warning" title="Taxon not matched to the GBIF Backbone Taxonomy">UNCONTROLLED_TAXON</span>'.html_safe
    end
  end
end
