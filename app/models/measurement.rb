class Measurement < ApplicationRecord
  belongs_to :sample
  belongs_to :lab
  actable
end
