namespace :xronos do
  namespace :c14s do
    desc "Merge exact-duplicate c14s"
    task deduplicate: :environment do
      Rake::Task["xronos:deduplicate"].reenable
      Rake::Task["xronos:deduplicate"].invoke("C14")
    end
  end
end
