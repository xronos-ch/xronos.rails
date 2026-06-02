# == Schema Information
#
# Table name: measurement_states
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
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
