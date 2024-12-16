# == Schema Information
#
# Table name: chronologies
#
#  id                   :bigint           not null, primary key
#  certainty            :string
#  chronology_type      :string
#  method               :string
#  name                 :string
#  parameters           :jsonb
#  standardizing_method :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Chronology < ApplicationRecord
  has_many :dendros
end
