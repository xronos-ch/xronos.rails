# frozen_string_literal: true

class Site
  # Runs the coordinate check against the configured reference layers.
  class WaterCheck
    REFERENCE_VERSION = 'natural-earth-5.1.2'
    MINIMUM_DISTANCE_METERS = 3000
    CACHE_KEY = "site-water-check/v1/#{REFERENCE_VERSION}/#{MINIMUM_DISTANCE_METERS}".freeze

    def self.report
      cache.read(CACHE_KEY)
    end

    def self.cache
      # Development typically disables caching or uses a process-local store.
      return Rails.cache unless Rails.env.development?

      ActiveSupport::Cache::FileStore.new(Rails.root.join('tmp/cache/site_water_check'))
    end

    def initialize(reference: nil)
      @reference = reference
    end

    def run(persist: false)
      reference = @reference || NaturalEarthWater.new(Rails.configuration.x.natural_earth.data_dir)
      findings = collect_findings(reference)
      findings.sort_by! { |finding| [-finding.fetch(:distance_meters), finding.fetch(:site_id)] }
      publish(findings) if persist
      findings
    end

    private

    def collect_findings(reference)
      Site.where(lat: -90..90, lng: -180..180).select(:id, :lat, :lng).find_each.filter_map do |site|
        distance = reference.distance_to_shore(site.lng, site.lat)
        next unless distance && distance >= MINIMUM_DISTANCE_METERS

        { site_id: site.id, lat: site.lat, lng: site.lng, distance_meters: distance.round }
      end
    end

    def publish(findings)
      report = { checked_at: Time.current, findings: findings.index_by { |finding| finding.fetch(:site_id) } }
      raise IOError, 'Could not cache water check report' unless self.class.cache.write(CACHE_KEY, report)
    end
  end
end
