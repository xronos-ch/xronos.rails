require 'rails_helper'

RSpec.describe "Curates", type: :request do

  describe "GET /view" do
    it "returns http success" do
      get "/curate/view"
      expect(response).to have_http_status(:success)
    end
  end

end
