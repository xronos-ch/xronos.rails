module LinkedResourcesHelper
  def linked_resource_label(status)
    status.to_s.upcase
  end

  def linked_resource_description(status)
    case status
    # Sites
    when :missing_wikidata_link
      "No Wikidata Link has yet been provided"
    else
      ""
    end
  end

  def linked_resource_badge(status)
    content_tag :span, title: linked_resource_description(status), class: "badge text-bg-warning" do
      linked_resource_label(status)
    end
  end
end
