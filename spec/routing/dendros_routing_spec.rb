require "rails_helper"

RSpec.describe DendrosController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/dendros").to route_to("dendros#index")
    end

    it "routes to #new" do
      expect(get: "/dendros/new").to route_to("dendros#new")
    end

    it "routes to #show" do
      expect(get: "/dendros/1").to route_to("dendros#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/dendros/1/edit").to route_to("dendros#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/dendros").to route_to("dendros#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/dendros/1").to route_to("dendros#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/dendros/1").to route_to("dendros#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/dendros/1").to route_to("dendros#destroy", id: "1")
    end
  end
end
