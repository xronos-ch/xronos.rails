namespace :xronos do
  namespace :sites do

    desc "Destroy site by ID"
    task destroy: :environment do
      abort "ID must be set" unless ENV["ID"]
      ENV["MODEL"] ||= "Site"
      Rake::Task["xronos:destroy"].invoke
    end

  end
end
