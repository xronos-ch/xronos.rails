namespace :xronos do
  namespace :samples do
    desc "Merge exact-duplicate samples"
    task deduplicate: :environment do
      Rake::Task["xronos:deduplicate"].reenable
      Rake::Task["xronos:deduplicate"].invoke("Sample")
    end
  end
end
