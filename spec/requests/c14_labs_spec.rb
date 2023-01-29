require 'rails_helper'

RSpec.describe "/c14_labs", type: :request do
  let(:valid_attributes) {
    FactoryBot.attributes_for :c14_lab
    #skip("Add a hash of attributes valid for your model")
  }

  before do
    @user = FactoryBot.create(:user)
    @admin = FactoryBot.create(:admin)
  end

  describe "GET /index" do
    it "renders a successful response" do
      C14Lab.create! valid_attributes
      get c14_labs_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      c14_lab = C14Lab.create! valid_attributes
      get c14_lab_url(c14_lab)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      sign_in @user
      get new_c14_lab_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "render a successful response" do
      sign_in @admin
      c14_lab = C14Lab.create! valid_attributes
      get edit_c14_lab_url(c14_lab)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid user" do
      it "creates a new C14Lab" do
        sign_in @admin
        
        expect {
          post c14_labs_url, params: { c14_lab: valid_attributes }
        }.to change(C14Lab, :count).by(1)
      end

      it "redirects to the created c14_lab" do
        sign_in @user
        
        post c14_labs_url, params: { c14_lab: valid_attributes }
        expect(response).to redirect_to :action => :show,
                                     :id => assigns(:c14_lab).id
      end
    end

    context "with invalid user" do
      it "does not create a new C14Lab" do
        
        expect {
          post c14_labs_url, params: { c14_lab: valid_attributes }, headers: { "HTTP_REFERER" => "http://foo.com" }
        }.to change(C14Lab, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        
        post c14_labs_url, params: { c14_lab: valid_attributes }, headers: { "HTTP_REFERER" => "http://foo.com" }
        expect(response).not_to be_successful
      end
    end
  end

  describe "PATCH /update" do
    context "with valid user" do
      let(:new_attributes) {
        FactoryBot.attributes_for :c14_lab
      }

      it "updates the requested c14_lab" do
        sign_in @admin
        
        c14_lab = C14Lab.create! valid_attributes
        patch c14_lab_url(c14_lab), params: { c14_lab: new_attributes }
        c14_lab.reload
        expect(c14_lab.name).to eq(new_attributes[:name])
        expect(c14_lab.active).to eq(new_attributes[:active])
        
        #skip("Add assertions for updated state")
      end

      it "redirects to the c14_lab" do
        sign_in @admin
        
        c14_lab = C14Lab.create! valid_attributes
        patch c14_lab_url(c14_lab), params: { c14_lab: new_attributes }
        c14_lab.reload
        expect(response).to redirect_to(c14_lab_url(c14_lab))
      end
    end

    context "with invalid user" do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        
        c14_lab = C14Lab.create! valid_attributes
        patch c14_lab_url(c14_lab), params: { c14_lab: valid_attributes }, headers: { "HTTP_REFERER" => "http://foo.com" }
        expect(response).not_to be_successful
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested c14_lab" do
      sign_in @admin
      
      c14_lab = C14Lab.create! valid_attributes
      expect {
        delete c14_lab_url(c14_lab)
      }.to change(C14Lab, :count).by(-1)
    end

    it "redirects to the c14_labs list" do
      sign_in @admin
      
      c14_lab = C14Lab.create! valid_attributes
      delete c14_lab_url(c14_lab)
      expect(response).to redirect_to(c14_labs_url)
    end
  end
end