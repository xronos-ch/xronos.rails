Rails.application.config.assets.paths.concat [
  # Bootstrap Icons web font
  Rails.root.join("node_modules", "bootstrap-icons", "font"),
]
Rails.application.config.assets.precompile += %w( frontend.css )
