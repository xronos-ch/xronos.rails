require 'rails_helper'

RSpec.describe "/dendros", type: :request do
  # Create users with and without admin privileges
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  # Valid and invalid attributes for the Dendro model
  let(:valid_attributes) {
    {
      sample_id: create(:sample).id, # Ensure a valid associated sample is created
      series_code: "RUSS068EN",
      name: "Dendro Sample",
      start_year: 1246,
      end_year: 1698
    }
  }

  let(:invalid_attributes) {
    { series_code: nil, name: nil, sample_id: nil }
  }

  # Devise helpers for authentication
  include Devise::Test::IntegrationHelpers

  describe "GET /index" do
    it "renders a successful response for visitors" do
      create(:dendro)
      get dendros_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response for visitors" do
      dendro = create(:dendro)
      get dendro_url(dendro)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "as an admin user" do
      before { sign_in admin_user }

      it "creates a new Dendro" do
        expect {
          post dendros_url, params: { dendro: valid_attributes }
        }.to change(Dendro, :count).by(1)
      end

      it "redirects to the created dendro" do
        post dendros_url, params: { dendro: valid_attributes }
        expect(response).to redirect_to(dendro_url(Dendro.last))
      end
    end

    context "as a regular user" do
      before { sign_in regular_user }

      it "creates a new Dendro" do
        expect {
          post dendros_url, params: { dendro: valid_attributes }
        }.to change(Dendro, :count).by(1)
      end

      it "redirects to the created dendro" do
        post dendros_url, params: { dendro: valid_attributes }
        expect(response).to redirect_to(dendro_url(Dendro.last))
      end
    end
  end

  describe "PATCH /update" do
    let(:new_attributes) {
      { name: "Updated Name" }
    }

    context "as an admin user" do
      before { sign_in admin_user }

      it "updates the requested dendro" do
        dendro = create(:dendro)
        patch dendro_url(dendro), params: { dendro: new_attributes }
        dendro.reload
        expect(dendro.name).to eq("Updated Name")
      end

      it "redirects to the dendro" do
        dendro = create(:dendro)
        patch dendro_url(dendro), params: { dendro: new_attributes }
        expect(response).to redirect_to(dendro_url(dendro))
      end
    end

    context "as a regular user" do
      before { sign_in regular_user }

      it "does not update the dendro" do
        dendro = create(:dendro)
        patch dendro_url(dendro), params: { dendro: new_attributes }
        dendro.reload
        expect(dendro.name).not_to eq("Updated Name")
      end

      it "returns a forbidden status" do
        dendro = create(:dendro)
        patch dendro_url(dendro), params: { dendro: new_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /destroy" do
    context "as an admin user" do
      before { sign_in admin_user }

      it "destroys the requested dendro" do
        dendro = create(:dendro)
        expect {
          delete dendro_url(dendro)
        }.to change(Dendro, :count).by(-1)
      end
      it "redirects to the dendros list" do
        dendro = create(:dendro)
        delete dendro_url(dendro)
        expect(response).to redirect_to(dendros_url)
      end
    end

    context "as a regular user" do
      before { sign_in regular_user }

      it "does not destroy the dendro" do
        dendro = create(:dendro)
        expect {
          delete dendro_url(dendro)
        }.not_to change(Dendro, :count)
      end

      it "returns a forbidden status" do
        dendro = create(:dendro)
        delete dendro_url(dendro)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end