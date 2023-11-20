module ApplicationHelper

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

  # Bootstrap Icons (icon font method)
  def bs_icon(icon, options = {})
    classes = ["bi-#{icon}"].append(options.delete(:class)).compact
    content_tag :i, "", options.merge(class: classes)
  end

  def create_icon(options = {})
    bs_icon "plus", options
  end

  def edit_icon(options = {})
    bs_icon "pencil-fill", options
  end

  def delete_icon(options = {})
    bs_icon "trash-fill", options
  end

  def confirm_icon(options = {})
    bs_icon "check", options
  end

  def cancel_icon(options = {})
    bs_icon "x", options
  end

  def active_class(path)
    "active" if current_page?(path)
  end

  def active_aria(path)
    'aria-current="page"'.html_safe if current_page?(path)
  end

  def na_value
    '<abbr title="Unknown or missing value" class="initialism text-muted">NA</abbr>'.html_safe
  end

  def tick_or_cross(bool)
    bool ? bs_icon("check") : bs_icon("x")
  end

  def to_dms(dd, axis)
    minutes = dd%1.0*60
    seconds = minutes%1.0*60
    suffix = case
             when (dd<0 && axis=="lon")
               "W"
             when (dd>=0 && axis=="lon")
               "E"
             when (dd<0 && axis=="lat")
               "S"
             when (dd>0 && axis=="lat")
               "N"
             else
               "Can not determine N/E/S/W"
             end

    return dd.abs.floor.to_s + "° " + minutes.floor.to_s + "' " + seconds.floor.to_s + '" ' + suffix
  end

  def javascript_exists?(script)
    script = "#{Rails.root}/app/javascript/packs/#{params[:controller]}.js"
    File.exists?(script) || File.exists?("#{script}.coffee") || File.exists?("#{script}.erb") 
  end

  def markdown(str)
    Kramdown::Document.new(str).to_html.html_safe
  end

  def md(str)
    sanitize Kramdown::Document.new(str)
      .to_html
      .remove('<p>')
      .remove('</p>')
      .html_safe
  end

end

