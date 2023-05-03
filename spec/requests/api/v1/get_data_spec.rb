require 'rails_helper'

RSpec.describe 'Data', type: :request do
  describe 'GET /api/v1/data' do
    
    before do
      FactoryBot.create_list(:c14, 10)
      get '/api/v1/data'
    end
  
    it 'returns all C14s' do
      expect(json.size).to eq(C14.count)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(:success)
    end
    
    specify do
      expect(json.count).to eq C14.count
      expect(json).to match_response_schema('apiv1')
    end
    
    it 'processes a site without site' do
      this_date = FactoryBot.create(:c14)
      this_date.context.site = nil
      get '/api/v1/data'
      expect(response).to have_http_status(:success)
    end
    
    it 'processes a site without site_types' do
      this_date = FactoryBot.build(:c14)
      this_date.sample.context.site.site_types = []
      this_date.save
      get '/api/v1/data'
      expect(response).to have_http_status(:success)
    end
  end
end
