require_relative 'boot'
require 'rails/all'
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Xronos
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_controller.action_on_unpermitted_parameters = :raise

    # Compress text responses
    config.middleware.use Rack::Deflater
    config.middleware.use Rack::Brotli
  end
end
