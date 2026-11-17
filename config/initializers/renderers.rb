ActionController::Renderers.add :csv do |obj, options|
  self.content_type = Mime[:csv]
  self.response_body = obj.copy_to_enumerator(buffer_lines: 100)
end
