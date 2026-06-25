# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.paths.concat [
                                               # Bootstrap Icons web font
                                               Rails.root.join("node_modules", "bootstrap-icons", "font"),
                                               # Fontsource variable fonts
                                               Rails.root.join("node_modules", "@fontsource-variable", "inter", "files"),
                                               Rails.root.join("node_modules", "@fontsource-variable", "raleway", "files"),
                                               Rails.root.join("node_modules", "@fontsource", "fira-mono", "files"),
                                             ]

Rails.application.config.assets.precompile += %w( frontend.css )