class Breadcrumbs::Render::Bootstrap < Breadcrumbs::Render::Base
  def render
    content_tag :nav, aria: { label: "breadcrumb" } do
      content_tag :ol, class: "breadcrumb" do
        breadcrumbs.items.map { |item|
          list_item(item, item == breadcrumbs.items.last)
        }.join.html_safe
      end
    end
  end

  def list_item(item, active)
    text, url, options = *item
    content_tag :li, li_options(options, active) do
      unless url.blank? or active
        content_tag :a, text, href: url
      else
        text
      end
    end
  end

  def li_options(options, active)
    if active
      options.merge(
        class: "breadcrumb-item active", 
        aria: { current: "page" }
      )
    else
      options.merge(class: "breadcrumb-item")
    end
  end
end
