namespace :xronos do
  namespace :sites do

    desc "Merge exact-duplicate sites"
    task deduplicate: :environment do
      Rake::Task["xronos:deduplicate"].reenable
      Rake::Task["xronos:deduplicate"].invoke("Site")
    end

    desc "Destroy site by ID"
    task destroy: :environment do
      abort "ID must be set" unless ENV["ID"]
      ENV["MODEL"] ||= "Site"
      Rake::Task["xronos:destroy"].invoke
    end

  end
end
