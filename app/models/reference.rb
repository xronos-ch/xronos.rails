class Reference < ApplicationRecord

  validates :short_ref, presence: true

  has_and_belongs_to_many :measurements

  has_and_belongs_to_many :fell_phases

end
