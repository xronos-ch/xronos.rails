class CountrySuggestionsController < ApplicationController
  def index
    authorize! :country_suggestion, Site

    latitude = Float(params[:lat], exception: false)
    longitude = Float(params[:lng], exception: false)
    coordinates = Coordinates.new(longitude, latitude)

    return head :unprocessable_entity unless coordinates.valid?

    country = Site.new(lat: latitude, lng: longitude).country_from_coordinates

    render json: {
      country_code: country&.alpha2,
      country_name: country&.iso_short_name
    }
  end
end
