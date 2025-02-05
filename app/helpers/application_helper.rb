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
    bs_icon "pencil", options
  end

  def delete_icon(options = {})
    bs_icon "trash", options
  end

  def confirm_icon(options = {})
    bs_icon "check-lg", options
  end

  def cancel_icon(options = {})
    bs_icon "x-lg", options
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

  def floating_button(path, options = {})
    default_classes = "d-block position-absolute top-0 start-100 small"
    if options.has_key?(:class)
      options[:class] = options[:class] + " " + default_classes
    else
      options[:class] = default_classes
    end

    options[:title] = "Edit" unless options.has_key?(:title)
    
    content_tag :div, class: "position-relative" do
      link_to path, **options do 
        bs_icon "pencil"
      end
    end
  end

  # Generates a Bootstrap-styled tristate radio button group using radio_button_tag.
    #
    # Parameters:
    #   form         - the form builder
    #   field        - the attribute name (e.g. :waney_edge)
    #   options      - a hash to customize the output; defaults are provided below.
    #
    # Defaults:
    #   :overall_label => field.humanize
    #   :true_value    => "true"
    #   :false_value   => "false"
    #   :na_value      => ""
    #   :true_label    => "Yes"
    #   :false_label   => "No"
    #   :na_label      => "N/A"
    #   :true_class    => "btn btn-outline-success"
    #   :false_class   => "btn btn-outline-danger"
    #   :na_class      => "btn btn-outline-secondary"
    #   :name          => "#{form.object_name}[#{field}]"
    #   :true_id       => a sanitized ID for the true radio (default: sanitized_form_object_name_field_true)
    #   :false_id      => sanitized_form_object_name_field_false
    #   :na_id         => sanitized_form_object_name_field_na
    #   :current_value => form.object.try(field)
    #
    # Usage:
    #   <%= tristate_radio_button_group(f, :waney_edge, overall_label: "Waney Edge?",
    #           name: "filter[dendros][waney_edge]",
    #           current_value: @data.filters.dig("dendros", "waney_edge")) %>
    def tristate_radio_button_group(form, field, options = {})
      # Sanitize the form's object name (replace [ and ] with underscores)
      sanitized_object_name = form.object_name.to_s.gsub(/[\[\]]/, "_")
      defaults = {
        overall_label: field.to_s.humanize,
        true_value: "true",
        false_value: "false",
        na_value: "",
        true_label: "Yes",
        false_label: "No",
        na_label: "N/A",
        true_class: "btn btn-outline-success",
        false_class: "btn btn-outline-danger",
        na_class: "btn btn-outline-secondary",
        name: "#{form.object_name}[#{field}]",
        true_id: "#{sanitized_object_name}_#{field}_true",
        false_id: "#{sanitized_object_name}_#{field}_false",
        na_id: "#{sanitized_object_name}_#{field}_na",
        current_value: form.object.try(field)
      }
      opts = defaults.merge(options)
      current_value = opts[:current_value]

      content_tag(:div, class: "row") do
        content_tag(:div, class: "col") do
          safe_join([
            # Overall label
            content_tag(:label, opts[:overall_label], class: "form-label d-block"),
            # Button group container
            content_tag(:div, class: "btn-group", role: "group", "aria-label" => opts[:overall_label]) do
              safe_join([
                # Yes radio button
                radio_button_tag(opts[:name], opts[:true_value], current_value.to_s == opts[:true_value],
                  class: "btn-check", id: opts[:true_id]),
                label_tag(opts[:true_id], opts[:true_label], class: opts[:true_class]),
                # No radio button
                radio_button_tag(opts[:name], opts[:false_value], current_value.to_s == opts[:false_value],
                  class: "btn-check", id: opts[:false_id]),
                label_tag(opts[:false_id], opts[:false_label], class: opts[:false_class]),
                # N/A radio button
                radio_button_tag(opts[:name], opts[:na_value], current_value.nil?,
                  class: "btn-check", id: opts[:na_id]),
                label_tag(opts[:na_id], opts[:na_label], class: opts[:na_class])
              ])
            end
          ])
        end
      end
    end
end

