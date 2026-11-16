# frozen_string_literal: true

namespace :xronos do
  namespace :import do
    desc 'Import RADONB radiocarbon dates'
    task :radonb, %i[dir source_url] => :environment do |_task, args|
      dir, source_url = args.values_at(:dir, :source_url)
      unless dir.present? && source_url.present? && args.extras.empty?
        abort 'Usage: bin/rails "xronos:import:radonb[dir,source_url]"'
      end
      abort "Source directory not found: #{dir}" unless Dir.exist?(dir)
      admin = User.find(ENV.fetch('ADMIN_USER_ID') { abort 'ADMIN_USER_ID must be set' })
      Xronos::RadonbImport.import_snapshot!(dir: dir, source_url: source_url, admin: admin)
    end
  end
end
