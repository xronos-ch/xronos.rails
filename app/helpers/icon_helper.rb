##
# Helper methods for rendering icons
module IconHelper

  def xr_icon(model, options = {}, html_options = {})
    filename = options.key?(:light) ? model.icon.sub(/\.svg\z/, '-light.svg') : model.icon
    attributes = html_options.except(:alt)
    label = html_options.fetch(:alt) { model.label }

    embedded_svg(filename, attributes, label: label)
  end

  def simple_icon(slug)
    embedded_svg("simple_icons/#{slug}.svg", class: 'simple-icon')
  end

  def bs_icon(icon, options = {})
    return ''.html_safe unless icon.to_s.match?(/\A[a-z0-9-]+\z/)

    path = Rails.root.join('node_modules/bootstrap-icons/icons', "#{icon}.svg")
    return ''.html_safe unless path.file?

    render_icon_svg(path.read, options)
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

  ##
  # Icon for supersede events (record superseded/merged)
  def supersede_icon(options = {})
    bs_icon "arrow-right", options
  end

  ##
  # Icon for restore events (record restored from supersession)
  def restore_icon(options = {})
    bs_icon "arrow-counterclockwise", options
  end

  def embedded_svg(filename, options = {}, label: nil, **attributes)
    asset = Rails.application.assets.load_path.find(filename)
    return ''.html_safe unless asset

    render_icon_svg(asset.content, options.merge(attributes), label: label)
  end

  def markdown_toolbar
    [
      ['toggleBold', 'type-bold', 'Bold'],
      ['toggleItalic', 'type-italic', 'Italic'],
      ['toggleStrikethrough', 'type-strikethrough', 'Strikethrough'],
      '|',
      ['toggleHeadingSmaller', 'hash', 'Heading'],
      ['toggleHeadingSmaller', 'caret-down-fill', 'Heading Smaller'],
      ['toggleHeadingBigger', 'caret-up-fill', 'Heading Bigger'],
      ['toggleHeading1', 'type-h1', 'Heading 1'],
      ['toggleHeading2', 'type-h2', 'Heading 2'],
      ['toggleHeading3', 'type-h3', 'Heading 3'],
      '|',
      ['toggleCodeBlock', 'code-slash', 'Code'],
      ['toggleBlockquote', 'chat-quote', 'Quote'],
      ['toggleOrderedList', 'list-ol', 'Ordered List'],
      ['toggleUnorderedList', 'list-ul', 'Unordered List'],
      '|',
      ['cleanBlock', 'x-circle', 'Clean Block'],
      ['drawLink', 'link-45deg', 'Insert Link'],
      ['drawImage', 'file-image', 'Insert Image'],
      ['drawImage', 'cloud-upload', 'Upload Image'],
      ['drawTable', 'table', 'Insert Table'],
      ['drawHorizontalRule', 'dash-lg', 'Insert Horizontal Rule'],
      '|',
      ['togglePreview', 'eye-fill', 'Preview'],
      ['toggleSideBySide', 'layout-text-sidebar-reverse', 'Side by Side'],
      ['toggleFullScreen', 'arrows-fullscreen', 'Fullscreen'],
      '|',
      ['guide', 'info-circle', 'Markdown Guide'],
      ['undo', 'arrow-counterclockwise', 'Undo'],
      ['redo', 'arrow-clockwise', 'Redo']
    ].map do |item|
      next item if item == '|'

      action, icon, title = item
      { action: action, icon: icon, title: title, svg: bs_icon(icon) }
    end
  end

  private

  def render_icon_svg(source, options, label: nil)
    svg = Nokogiri::XML.fragment(source).element_children.find { |node| node.name == 'svg' }
    return ''.html_safe unless svg

    label ||= options[:title] || svg.element_children.find { |node| node.name == 'title' }&.text
    svg['width'] = '1em'
    svg['height'] = '1em'
    svg['class'] = class_names('app-icon', options[:class])
    if label.present?
      svg['role'] = 'img'
      svg['aria-label'] = label
    else
      svg.remove_attribute('role')
      svg['aria-hidden'] = 'true'
    end

    options.except(:class).each { |name, value| svg[name.to_s.tr('_', '-')] = value.to_s unless value.nil? }
    svg.to_xml.html_safe
  end
end
