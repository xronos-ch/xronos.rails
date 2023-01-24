# == Schema Information
#
# Table name: measurement_states
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_measurement_states_on_name  (name)
#
class MeasurementState < ApplicationRecord

    has_many :measurements
    has_paper_trail

    validates :name, presence: true

end
