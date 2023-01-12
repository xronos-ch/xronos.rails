# This file should contain all the record creation needed to seed the database with its default values.
#
# Radiocarbon seed data is a random sample from p3k14c v1.0.0
# <https://core.tdar.org/dataset/459164/p3k14c>
#

require 'factory_bot'
require 'open-uri'
require 'csv'

FactoryBot.create(:user, :admin)

FactoryBot.create_list(:c14, 100)
