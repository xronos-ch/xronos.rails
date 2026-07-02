##
# Helper methods for the navbar
module NavbarHelper

  def meta(name, default = nil)
    content_for?(name) ? content_for(name) : default
  end

  ##
  # Returns "active" if a path is the current page
  def active_class(path)
    "active" if current_page?(path)
  end

  ##
  # Returns aria-current attribute if a path is the current page
  def active_aria(path)
    'aria-current="page"'.html_safe if current_page?(path)
  end
end
