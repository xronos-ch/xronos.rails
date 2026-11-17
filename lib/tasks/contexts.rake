namespace :xronos do
  namespace :contexts do
    desc "Merge exact-duplicate contexts"
    task deduplicate: :environment do
      Rake::Task["xronos:deduplicate"].reenable
      Rake::Task["xronos:deduplicate"].invoke("Context")
    end
  end
end
