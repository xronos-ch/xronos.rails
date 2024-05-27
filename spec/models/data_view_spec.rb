# == Schema Information
#
# Table name: data_views
#
#  id                      :bigint
#  bp                      :integer
#  cal_bp                  :integer
#  cal_std                 :integer
#  country                 :string
#  delta_c13               :float
#  ecochronological_units  :json
#  feature                 :string
#  feature_type            :string
#  labnr                   :string
#  lat                     :text
#  lng                     :text
#  material                :string
#  periods                 :json
#  reference               :json
#  site                    :string
#  site_type               :string
#  species                 :string
#  std                     :integer
#  typochronological_units :json
#
require 'rails_helper'

RSpec.describe DataView, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
