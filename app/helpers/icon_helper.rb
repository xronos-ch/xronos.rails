##
# Helper methods for rendering icons
module IconHelper

  #
  # XRONOS icons
  #

  ##
  # Render XRONOS icons as SVGs
  def xr_icon(model, options = {}, html_options = {})
    icon = model.icon

    if options.has_key?(:light)
      icon = icon.split(".")
      icon = icon[0] + "-light." + icon[1]
    end

    unless html_options.has_key?(:alt)
      html_options[:alt] = model.label
    end

    # Set intrinsic dimensions (actual display dimensions assumed to be set by CSS!)
    html_options[:width] = 72
    html_options[:height] = 72

    image_tag icon, html_options
  end

  #
  # Simple Icons <https://simpleicons.org/>
  #

  ##
  # Render Simple Icon as an embedded SVG
  def simple_icon(slug)
    content_tag :span, class: "svg-icon svg-baseline" do
      embedded_svg "simple_icons/#{slug}.svg", 
        height: 32, 
        role: "graphics-symbol", 
        class: "simple-icon"
    end
  end

  ##
  # Embed an SVG directly in rendered markup
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


  #
  # Bootstrap icons
  #

  ##
  # Render Bootstrap icon with embedded font
  def bs_icon(icon, options = {})
    classes = ["bi-#{icon}"].append(options.delete(:class)).compact
    content_tag :i, "", options.merge(class: classes)
  end

  ##
  # Standard icon for the create action (for use in buttons)
  def create_icon(options = {})
    bs_icon "plus", options
  end

  ##
  # Standard inline icon for the create action (without a button)
  def create_inline_icon(options = {})
    bs_icon "plus-square", options
  end

  ##
  # Standard icon for the edit action (for use in buttons)
  def edit_icon(options = {})
    bs_icon "pencil", options
  end

  ##
  # Standard inline icon for the edit action (without a button)
  def edit_inline_icon(options = {})
    bs_icon "pencil-square", options
  end

  ##
  # Standard icon for delete/destroy/cancel actions (for use in buttons)
  def delete_icon(options = {})
    bs_icon "x-lg", options
  end

  ##
  # Standard inline icon for delete/destroy/cancel actions (without a button)
  def delete_inline_icon(options = {})
    bs_icon "x-square", options
  end

  ##
  # Standard icon for approving changes (for use in buttons)
  def confirm_icon(options = {})
    bs_icon "check-lg", options
  end

  ##
  # Standard inline icon for approving changes (without a button)
  def confirm_inline_icon(options = {})
    bs_icon "check-square", options
  end

end
