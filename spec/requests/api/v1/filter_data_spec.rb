require 'rails_helper'

RSpec.describe 'Data', type: :request do
  
  before(:all) do
    @c14s = FactoryBot.create_list(:c14, 10)
  end
  
  describe 'query_labnr' do
    
    before do
      @labnr = @c14s.first.lab_identifier
      get '/api/v1/data?query_labnr=' + @labnr
    end
  
    it 'returns all C14s with that lab identifier' do
      expect(json.size).to eq(C14.where(lab_identifier: @labnr).count)
    end
    
    it 'returns only C14s with that lab identifier' do
      labnrs = json.collect {|j| j['measurement']['labnr']}.uniq
      expect(labnrs.length).to eq 1
      expect(labnrs.to_s).to include(@labnr)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'query_labnr' do
    
    before do
      @site = @c14s.first.site.name
      get '/api/v1/data?query_site=' + @site
    end
  
    it 'returns all C14s with that site name' do
      expect(json.size).to eq(C14.includes(sample: { context: :site }).where(site: {name: @site}).count)
    end
    
    it 'returns only C14s with that site name' do
      sites = json.collect {|j| j['measurement']['site']}.uniq
      expect(sites.length).to eq 1
      expect(sites.to_s).to include(@site)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'query_site_type' do
    
    before do
      @site_type = @c14s.first.site.site_types.first.name
      get '/api/v1/data?query_site_type=' + @site_type
    end
  
    it 'returns all C14s with that site name' do
      expect(json.size).to eq(C14.includes(sample: { context: { site: :site_types } }).where(site: {site_types: {name: @site_type}}).count)
    end
    
    it 'returns only C14s with that site type' do
      site_types = json.collect {|j| j['measurement']['site_type']}.uniq
      expect(site_types.length).to eq 1
      expect(site_types.to_s).to include(@site_type)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'query_country' do
    
    before do
      @country = @c14s.first.site.country_code
      get '/api/v1/data?query_country=' + @country
    end
  
    it 'returns all C14s with that country' do
      expect(json.size).to eq(C14.includes(sample: { context: :site }).where(site: {country_code: @country}).count)
    end
    
    it 'returns only C14s with that country' do
      countries = json.collect {|j| j['measurement']['country']}.uniq
      expect(countries.length).to eq 1
      expect(countries.to_s).to include(@country)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'query_feature' do
    
    before do
      @feature = @c14s.first.context.name
      get '/api/v1/data?query_feature=' + @feature
    end
  
    it 'returns all C14s with that feature' do
      expect(json.size).to eq(C14.includes(sample: :context).where(context: {name: @feature}).count)
    end
    
    it 'returns only C14s with that feature' do
      features = json.collect {|j| j['measurement']['feature']}.uniq
      expect(features.length).to eq 1
      expect(features.to_s).to include(@feature)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'query_material' do
    
    before do
      @material = @c14s.first.sample.material.name
      get '/api/v1/data?query_material=' + @material
    end
  
    it 'returns all C14s with that feature' do
      expect(json.size).to eq(C14.includes(sample: :material).where(sample: {materials: {name: @material}}).count)
    end
    
    it 'returns only C14s with that feature' do
      materials = json.collect {|j| j['measurement']['material']}.uniq
      expect(materials.length).to eq 1
      expect(materials.to_s).to include(@material)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'query_species' do
    
    before do
      @species = @c14s.first.sample.taxon.name
      get '/api/v1/data?query_species=' + @species
    end
  
    it 'returns all C14s with that species' do
      expect(json.size).to eq(C14.includes(sample: :taxon).where(sample: {taxons: {name: @species}}).count)
    end
  
    it 'returns only C14s with that species' do
      taxa = json.collect {|j| j['measurement']['species']}.uniq
      expect(taxa.length).to eq 1
      expect(taxa.to_s).to include(@species)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
    
  describe 'query_species | query_species' do
    
    before do
      @species = @c14s.first.sample.taxon.name
      @species2 = @c14s.second.sample.taxon.name
      
      get '/api/v1/data?query_species=' + @species + '%7C' + @species2
    end
  
    it 'returns all C14s with that species' do
      expect(json.size).to eq(C14.includes(sample: :taxon).where(sample: {taxons: {name: [@species, @species2]}}).count)
    end
  
    it 'returns only C14s with that species' do
      taxa = json.collect {|j| j['measurement']['species']}.uniq
      expect(taxa.length).to eq 2
      expect(taxa.to_s).to include(@species)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'query_labnr & query_species' do
    
    before do
      @labnr = @c14s.first.lab_identifier
      @species = @c14s.first.sample.taxon.name
      
      get '/api/v1/data?query_species=' + @species + '&query_labnr=' + @labnr
    end
  
    it 'returns all C14s with that species' do
      expect(json.size).to eq(C14.includes(sample: :taxon).where(sample: {taxons: {name: @species}}, lab_identifier: @labnr).count)
    end
  
    it 'returns only C14s with that species and lab_nr' do
      taxa = json.collect {|j| j['measurement']['species']}.uniq
      expect(taxa.length).to eq 1
      expect(taxa.to_s).to include(@species)
      labnrs = json.collect {|j| j['measurement']['labnr']}.uniq
      expect(labnrs.length).to eq 1
      expect(labnrs.to_s).to include(@labnr)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
  end
end
