##
# Miscellaneous helper methods
module ApplicationHelper

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

