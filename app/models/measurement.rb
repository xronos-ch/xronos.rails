class Measurement < ApplicationRecord
  actable
  belongs_to :sample
  belongs_to :lab
end
