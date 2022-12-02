# This file should contain all the record creation needed to seed the database with its default values.
#
# Radiocarbon seed data is a random sample from p3k14c v1.0.0
# <https://core.tdar.org/dataset/459164/p3k14c>
#

require 'factory_bot'
require 'open-uri'
require 'csv'

FactoryBot.create(:user, :admin)

ActiveRecord::Migration.say_with_time 'Seeding C14 data from p3k14c' do
  p3k14c_data = URI.open('https://raw.githubusercontent.com/people3k/p3k14c/1.0.0/inst/p3k14c_scrubbed_fuzzed.csv')
  p3k14c = CSV.parse(p3k14c_data, :headers=>true)
  nstart = rand(p3k14c.length - 999)
  p3k14c = p3k14c[nstart..nstart+999]

  p3k14c.each do |date|
    # Create or get site
    site_name = date["SiteName"]
    site_name = "Unknown" if site_name.blank?
    country = date["Country"]
    country = "Unknown" if country.blank?
    site = Site.where(
      name: site_name, 
      lat: date["Lat"], 
      lng: date["Long"], 
      country: Country.where(name: country).first_or_create!
    ).first_or_create!
    phase = site.site_phases.where(name: site_name).first_or_create!

    # Create associations through to measurement
    material = date["Material"]
    material = "Unknown" if material.blank?
    species = date["Taxa"]
    species = "Unknown" if species.blank?
    arch_object = phase.arch_objects.create!(
      material: Material.where(name: material).first_or_create!,
      species: Species.where(name: species).first_or_create!
    )
    sample = arch_object.samples.create!

    # Create measurement
    measurement = sample.measurements.create!(
      labnr: date["LabID"],
      lab: Lab.where(name: "Unknown").first_or_create!,
      c14_measurement: C14Measurement.create!(
        bp: date["Age"],
        std: date["Error"],
        delta_c13: date["d13C"],
        method: date["Method"],
        source_database: SourceDatabase.where(name: date["Source"]).first_or_create!
      ),
      measurement_state: MeasurementState.where(name: "original").first_or_create!
    )

    # Columns not used:
    # - Continent
    # - Province
    # - SiteID
    # - Period
    # - LocAccuracy
    # - References
  end
end

FactoryBot.create_list(:fell_phase, 2)
