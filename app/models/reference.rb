class Reference < ApplicationRecord

  has_paper_trail
  
  validates :short_ref, presence: true
  has_many :citations

end
