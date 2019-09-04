class SourceDatabase < ApplicationRecord

  has_many :c14_measurements, inverse_of: :source_database

end
