#!/bin/bash

#### create Relation Types ####

# countries
bin/rails generate scaffold country name:string abbreviation:string

# sites
bin/rails generate scaffold site name:string lat:integer lng:integer

bin/rails db:migrate RAILS_ENV=development

#### define interactions of Types by replacing the model scripts ####

echo "class Site < ApplicationRecord
	belongs_to :country
end" > 'app/models/site.rb'

