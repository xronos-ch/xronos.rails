#!/bin/bash

# countries
bin/rails generate scaffold country name:string abbreviation:string

# sites
bin/rails generate scaffold site name:string lat:integer lng:integer

bin/rails db:migrate RAILS_ENV=development