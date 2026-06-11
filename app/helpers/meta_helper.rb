module MetaHelper
  def meta(name, default = nil)
    content_for?(name) ? content_for(name) : default
  end
end
