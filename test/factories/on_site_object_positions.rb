FactoryBot.define do
  
  factory :on_site_object_position do
    feature { Faker::Books::Lovecraft.location }
    site_grid_square { Faker::Code.nric }
    coord_reference_system { "EPSG-4326" }
    coord_X { Faker::Address.longitude }
    coord_Y { Faker::Address.latitude }
    coord_Z {Faker::Number.between(from: 1, to: 8000)}
    feature_type
  end
  
end