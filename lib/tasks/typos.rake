namespace :xronos do
  namespace :typos do
    desc "Merge exact-duplicate typos"
    task deduplicate: :environment do
      Rake::Task["xronos:deduplicate"].reenable
      Rake::Task["xronos:deduplicate"].invoke("Typo")
    end
  end
end
