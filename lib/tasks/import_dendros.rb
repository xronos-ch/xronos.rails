require 'csv'
require 'json'
require 'securerandom' # For generating unique fallback identifiers

puts "Script is running!"

# Path to the CSV file
FILE_PATH = 'filtered_dendros_samples_import.csv'

# Helper to ensure data integrity
def find_or_create_taxon(species)
  return nil if species.nil?

  Taxon.find_or_create_by!(name: species.strip)
end

def find_or_create_site(lat, lng, name)
  return nil if lat.nil? || lng.nil?

  Site.find_or_create_by!(lat: lat.to_f, lng: lng.to_f) do |site|
    site.name = name.strip if name
  end
end

def find_or_create_context(site, name = nil)
  return nil if site.nil?

  Context.find_or_create_by!(site: site, name: name || "Unnamed Context")
end

def find_or_create_chronology(chronology_type)
  return nil if chronology_type.nil?

  Chronology.find_or_create_by!(chronology_type: chronology_type.strip)
end

def generate_short_ref(name, year)
  if name && year
    "#{name.split.first}-#{year}"
  else
    "ref-#{SecureRandom.hex(4)}" # Fallback to a unique short_ref
  end
end

def create_reference_for_contributor(contributor, year)
  return nil if contributor.nil?

  short_ref = generate_short_ref(contributor.strip, year)
  bibtex = "@misc{#{short_ref}, author={#{contributor.strip}}}"
  Reference.find_or_create_by!(short_ref: short_ref, bibtex: bibtex)
end

def create_citation_for_dendro(dendro, reference)
  Citation.find_or_create_by!(citing: dendro, reference: reference)
end

# Begin import process
ActiveRecord::Base.transaction do
  puts "Starting data import..."

  # Cache created objects to reduce DB queries
  taxons = {}
  sites = {}
  contexts = {}
  chronologies = {}

  # Read and process the CSV file
  CSV.foreach(FILE_PATH, headers: true) do |row|
    # Step 1: Handle Taxon (SPECIES)
    species = row['SPECIES']
    taxons[species] ||= find_or_create_taxon(species)

    # Step 2: Handle Site (lat/lng + NAME)
    lat, lng, name = row['lat'], row['lng'], row['NAME']
    site_key = "#{lat}_#{lng}"
    sites[site_key] ||= find_or_create_site(lat, lng, name)

    # Step 3: Handle Context
    site = sites[site_key]
    context_key = "#{site.id}_#{row['NAME']}"
    contexts[context_key] ||= find_or_create_context(site, row['NAME'])

    # Step 4: Handle Chronology (CHRONOLOGY_TYPE)
    chronology_type = row['CHRONOLOGY_TYPE']
    chronologies[chronology_type] ||= find_or_create_chronology(chronology_type)

    # Step 5: Handle Sample
    taxon = taxons[species]
    context = contexts[context_key]
    sample = Sample.find_or_create_by!(taxon: taxon, context: context) do |s|
      s.position_description = "Elevation: #{row['ELEVATION']}" if row['ELEVATION']
    end

    # Step 6: Handle Dendro
    measurements = row['measurements'] ? JSON.parse(row['measurements']) : []
    dendro = Dendro.create!(
      sample: sample,
      series_code: row['SERIES'],
      name: row['SERIES'],
      description: row['FILE'],
      start_year: row['START'].to_i,
      end_year: row['END'].to_i,
      measurements: measurements,
      chronology: chronologies[chronology_type]
    )

    # Step 7: Handle Contributor via Reference and Citation
    if row['CONTRIBUTOR']
      year = Time.now.year # Use 'END' year or fallback to current year
      reference = create_reference_for_contributor(row['CONTRIBUTOR'], year.to_i)
      create_citation_for_dendro(dendro, reference)
    end
  end

  puts "Data import completed successfully!"
end