namespace :xronos do
  namespace :citations do
    desc 'Merge exact-duplicate citations'
    task deduplicate: :environment do
      Rake::Task['xronos:deduplicate'].reenable
      Rake::Task['xronos:deduplicate'].invoke('Citation')
    end
  end
end
