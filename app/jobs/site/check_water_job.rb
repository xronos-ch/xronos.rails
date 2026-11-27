# frozen_string_literal: true

class Site
  # Refreshes the water location issues outside of the web request.
  class CheckWaterJob < ApplicationJob
    queue_as :default
    limits_concurrency to: 1, key: 'site-water-check'

    def perform
      Site::WaterCheck.new.run(persist: true)
    end
  end
end
