namespace :xronos do
  namespace :sites do

    # Place ne_10m_{ocean,lakes,coastline}.geojson in the worker's NATURAL_EARTH_DATA_DIR
    # (defaults to data/sources/natural_earth).
    # https://github.com/nvkelso/natural-earth-vector/tree/v5.1.2/geojson
    desc 'Check site coordinates against Natural Earth water polygons (DRY_RUN=1 to preview)'
    task check_water: :environment do
      if ENV['DRY_RUN'] == '1'
        findings = Site::WaterCheck.new.run
        puts "#{findings.size} sites at least #{Site::WaterCheck::MINIMUM_DISTANCE_METERS} m from shore in mapped water"
        findings.first(50).each do |finding|
          distance_km = (finding[:distance_meters] / 1000.0).round(1)
          coordinates = [finding[:lat], finding[:lng]].map { |coordinate| coordinate.to_s('F') }
          puts "#{finding[:site_id]}: #{coordinates.join(', ')} (~#{distance_km} km from shore)"
        end
      else
        Site::CheckWaterJob.perform_later
      end
    end

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
