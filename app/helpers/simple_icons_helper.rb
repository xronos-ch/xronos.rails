module SimpleIconsHelper

  def simple_icon(slug)
    content_tag :span, class: "svg-icon svg-baseline" do
      embedded_svg "simple_icons/#{slug}.svg", width: 32, height: 32, role: "graphics-symbol", class: "simple-icon"
    end
  end

  # Embed SVGs directly
  # adapted from https://blog.cloud66.com/using-svgs-in-a-rails-stack
  def embedded_svg(filename, options = {})
    assets = Rails.application.assets

    asset = assets.load_path.find(filename)

    if asset
      #file = asset.source.force_encoding("UTF-8")
      doc = Nokogiri::HTML::DocumentFragment.parse asset.content

      svg = doc.at_css "svg"
      options.each {|attr, value| svg[attr.to_s] = value}
      #svg["class"] = options[:class] if options[:class].present?
    else
      doc = "<!-- SVG #{filename} not found -->"
    end

    raw doc
  end

end
