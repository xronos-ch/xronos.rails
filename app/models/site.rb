# == Schema Information
#
# Table name: sites
#
#  id            :bigint           not null, primary key
#  country_code  :string
#  lat           :decimal(, )
#  lng           :decimal(, )
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_sites_on_country_code  (country_code)
#  index_sites_on_name          (name)
#
class Site < ApplicationRecord

  require 'net/http'
  require 'json'
  require 'uri'
    
  has_many :site_names
  has_many :contexts
  has_many :samples, through: :contexts
  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts
  has_many :citations, as: :citing
  has_many :references, through: :citations
  has_many :lod_links, as: :linkable, dependent: :destroy

  has_and_belongs_to_many :site_types, optional: true

  composed_of :coordinates, mapping: [%w(lng longitude), %w(lat latitude)], 
    allow_nil: true

  validates :name, presence: true

  accepts_nested_attributes_for :site_names, 
    reject_if: :all_blank, allow_destroy: true

  include Versioned
  include Supersedable

  include Duplicable
  duplicable :name, :lat, :lng, :country_code

  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = [ :missing_coordinates, :invalid_coordinates, :missing_country_code ]
  
  include NeedsLods
  @lods = [ :needs_wikidata_link ]

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words
  multisearchable against: :name
  
  scope :with_counts, -> {
    select <<~SQL
      sites.*,
      (
        SELECT COUNT(c14s.id) 
        FROM c14s
        JOIN samples ON samples.id = c14s.sample_id
        JOIN contexts ON contexts.id = samples.context_id
        WHERE contexts.site_id = sites.id
      ) AS c14s_count,
      (
        SELECT COUNT(typos.id) 
        FROM typos
        JOIN samples ON samples.id = typos.sample_id
        JOIN contexts ON contexts.id = samples.context_id
        WHERE contexts.site_id = sites.id
      ) AS typos_count
    SQL
  }

  def self.label
    "Site"
  end

  def self.icon
    "icons/site.svg"
  end

  def country
    return nil if country_code.blank?
    ISO3166::Country[country_code] || 
      ISO3166::Country.find_country_by_any_name(country_code)
  end

  def country_from_coordinates
    return nil if lat.blank? || lng.blank?

    result = Geocoder.search([lat, lng]).first
    if result && result.country_code.present?
      return ISO3166::Country[result.country_code]
    else
      return nil
    end
  end
  
  def country_code_from_coordinates
    return nil if lat.blank? || lng.blank?

    result = Geocoder.search([lat, lng]).first
    if result && result.country_code.present?
      return result.country_code.upcase
    else
      return nil
    end
  end
  


  def self.wikidata_match_candidates_batch(sites)
    # Generate a cache key based on site names
    cache_key = generate_cache_key(sites)

    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      site_names = extract_site_names(sites)
      sparql_query = build_sparql_query(site_names)
      response = execute_sparql_request(sparql_query)
      parse_wikidata_response(response)
    end
  end
 
  def n_c14s
    c14s.count
  end

  def n_typos
    typos.count
  end

  def recursive_references
    c14_references = c14s.map(&:references).reduce(:+)
    unless c14_references.nil?
      (references + c14_references).uniq
    else
      references
    end
  end

  def default_c14_curve
    return :IntCal20 unless lat.present?
    # TODO: what about the sea?
    # https://github.com/xronos-ch/xronos.rails/issues/326
    if lat >= 0
      :IntCal20
    else
      :SHCal20
    end
  end

  # Issues
  scope :missing_coordinates, -> { where("lat IS NULL OR lng IS NULL") }
  def missing_coordinates?
    lat.blank? or lng.blank?
  end

  scope :invalid_coordinates, -> { where("lat > 90 OR lat < -90 OR lng > 180 OR lng < -180") }
  def invalid_coordinates?
    unless missing_coordinates?
      coordinates.invalid_latitude? or coordinates.invalid_longitude?
    end
  end

  scope :missing_country_code, -> { where("country_code = '' OR country_code IS NULL") }
  def missing_country_code?
    country_code.blank?
  end
  
  scope :needs_wikidata_link, -> {
    where.not(id: WikidataLink.where(wikidata_linkable_type: "Site").select(:wikidata_linkable_id).distinct)
  }
  def needs_wikidata_link?
    wikidata_link.blank?
  end

  private

  # Generate a unique cache key for the batch of sites
  def self.generate_cache_key(sites)
    "wikidata_match_batch/#{Digest::MD5.hexdigest(sites.pluck(:name).sort.join(','))}"
  end

  # Extracts names from the sites
  def self.extract_site_names(sites)
    sites.pluck(:name).map { |name| "\"#{name}\"@en" }.join(" ")
  end

  # Builds the SPARQL query
  def self.build_sparql_query(site_names)
    <<-SPARQL
      SELECT ?item ?itemLabel ?itemDescription ?name
             (CONCAT("https://www.wikidata.org/wiki/", SUBSTR(STR(?item), 32)) AS ?itemURL) WHERE {
        VALUES ?name { #{site_names} }
        ?item wdt:P31 wd:Q839954.
        ?item rdfs:label ?name.
        SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
      }
    SPARQL
  end

  # Executes the SPARQL request
  def self.execute_sparql_request(sparql_query)
    url = URI("https://query.wikidata.org/sparql?query=#{URI.encode_www_form_component(sparql_query)}&format=json")
    request = Net::HTTP::Get.new(url)
    request['User-Agent'] = 'XRONOS/1.0 (martin.hinz@unibe.ch)'

    Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  # Parses the response from Wikidata
  def self.parse_wikidata_response(response)
    data = JSON.parse(response.body)

    data["results"]["bindings"]
      .group_by { |result| result.dig("name", "value") }
      .transform_values do |matches|
        matches.map do |match|
          OpenStruct.new(
            qid: match.dig("item", "value")&.split("/")&.last&.gsub(/^Q/i, ''),
            label: match.dig("itemLabel", "value"),
            description: match.dig("itemDescription", "value"),
            url: match.dig("itemURL", "value")
          )
        end
      end
  end
  
end
