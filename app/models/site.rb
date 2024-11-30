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

  has_many :site_names
  has_many :contexts
  has_many :samples, through: :contexts
  has_many :c14s, through: :contexts
  has_many :typos, through: :contexts
  has_many :citations, as: :citing
  has_many :references, through: :citations
  has_one :wikidata_link, as: :wikidata_linkable
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
  
  require 'net/http'
  require 'json'
  require 'uri'

   def wikidata_match_candidates
      Rails.cache.fetch("wikidata_match/#{name}", expires_in: 24.hours) do
        logger.debug "Wikidata SPARQL request for: #{name}"
        
        # Define the SPARQL query
        sparql_query = <<-SPARQL
          SELECT ?item ?itemLabel ?itemDescription (CONCAT("https://www.wikidata.org/wiki/", SUBSTR(STR(?item), 32)) AS ?itemURL) WHERE {
            ?item wdt:P31 wd:Q839954. # instance of archaeological site
            ?item rdfs:label "#{name}"@en. # label must match `name` exactly in English
            SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
          }
        SPARQL

        # Encode the query for use in the URL
        url = URI("https://query.wikidata.org/sparql?query=#{URI.encode_www_form_component(sparql_query)}&format=json")

        # Create an HTTP request and set the user agent
        request = Net::HTTP::Get.new(url)
        request['User-Agent'] = 'MyAppName/1.0 (your_email@example.com)' # Replace with your app name and contact

        # Execute the HTTP request
        response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
          http.request(request)
        end

        data = JSON.parse(response.body)

        # Extract the relevant data from the response
        data["results"]["bindings"].map do |result|
          OpenStruct.new(
            qid: result.dig("item", "value")&.split("/")&.last&.gsub(/^Q/i, ''), # Strip "Q" prefix
            label: result.dig("itemLabel", "value"),
            description: result.dig("itemDescription", "value"),
            url: result.dig("itemURL", "value"),
          )
        end
      end
    end
    
    def wikidata_match
      # Retrieve cached candidates and find an exact match by name
      match_candidates = wikidata_match_candidates
      #match_candidates.find { |candidate| candidate.label == name } if match_candidates.present?
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

end
