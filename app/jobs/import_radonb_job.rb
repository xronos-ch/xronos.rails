# frozen_string_literal: true

# Fetches and imports the latest RADONB export.
class ImportRadonbJob < ApplicationJob
  queue_as :default

  def perform(admin_id = ENV.fetch('RADONB_IMPORT_USER_ID'), archive = ENV.fetch('RADONB_IMPORT_ARCHIVE_DIR'))
    Xronos::RadonbImport.import_latest!(archive: archive, admin: User.find(admin_id))
  end
end
