# frozen_string_literal: true

namespace :xronos do
  namespace :import do
    desc 'Import RADONB radiocarbon dates'
    task :radonb, %i[version dir source_url] => :environment do |_task, args|
      version, dir, source_url = Xronos::ImportRunner.parse_args!(args)
      admin = User.find(ENV.fetch('ADMIN_USER_ID') { abort 'ADMIN_USER_ID must be set' })
      source = Source.register!(
        name: 'RADONB',
        version: version,
        path: dir,
        source_url: source_url
      )

      PaperTrail.request(whodunnit: admin.id.to_s) do
        Xronos::RadonbImport.new(source, csv_dir: dir).run!
      end
    end
  end
end
