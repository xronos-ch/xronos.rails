class Context < ApplicationRecord

  validates :name, presence: true

  belongs_to :site
  accepts_nested_attributes_for :site, :reject_if => proc { |attributes| attributes.all? { |key, value| key == "_destroy" || value.blank? || (value.is_a?(Hash) && value.values.all?(&:blank?)) } }
  validates_associated :site

  has_many :samples
  has_many :c14s, through: :samples
  has_many :typos, through: :samples
  has_paper_trail

end
