ActionController::Renderers.add :csv do |obj, options|
  self.content_type = Mime[:csv]
  obj.copy_to_string
end
