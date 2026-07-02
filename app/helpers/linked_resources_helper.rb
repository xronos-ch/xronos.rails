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

  # Render the icon for a linked resource, given its registered source
  # name (e.g. "Wikidata", "Pleiades"). Renders the source's logo SVG
  # (`app/assets/images/simple_icons/<icon>.svg`) if the source has an
  # `icon` attribute; renders a Bootstrap `share` icon as a placeholder
  # otherwise.
  def linked_resource_icon(source_name)
    source = LinkedResource::Source.find(source_name)

    return ''.html_safe if source.nil?

    if source.icon.present?
      simple_icon source.icon
    else
      bs_icon 'share'
    end
  end
end
