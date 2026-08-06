namespace :xronos do
  namespace :demo do

    desc "Create demo supersession events in the changelog for UI testing"
    task supersession: :environment do
      admin = User.find_by(admin: true) || User.first
      abort "No user found. Run db:seed first." unless admin

      PaperTrail.request.whodunnit = admin.id.to_s

      sites = (1..3).map { |i| Site.create!(name: "Demo Site #{i}") }
      canonical = Site.create!(name: "Canonical Demo Site")

      puts "Creating #{sites.size} demo sites..."

      # Site 1: supersede then restore (visible, has history)
      sites[0].supersede!(canonical, "Merged into canonical demo site")
      sites[0].restore!
      puts "Site 1: superseded into canonical, then restored."

      # Site 2: supersede and leave superseded (hidden, redirects to canonical)
      sites[1].supersede!(canonical, "This site was a duplicate")
      puts "Site 2: superseded into canonical (remains superseded)."

      # Site 3: no supersession (clean changelog)
      puts "Site 3: no supersession events."

      puts
      puts "Done. View changelogs at:"
      puts "  /sites/#{sites[0].id}  (supersede + restore history)"
      puts "  /sites/#{sites[1].id}  (redirects to canonical)"
      puts "  /sites/#{canonical.id} (canonical)"
    end

  end
end
