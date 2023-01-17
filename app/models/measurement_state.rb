class MeasurementState < ApplicationRecord

    has_many :measurements
    has_paper_trail

    validates :name, presence: true

end
