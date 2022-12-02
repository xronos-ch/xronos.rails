class SourceDatabase < ApplicationRecord
  has_paper_trail

  validates :name, presence: true

  has_many :c14s, inverse_of: :source_database

end
