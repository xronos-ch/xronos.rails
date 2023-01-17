class Sample < ApplicationRecord

  
  belongs_to :context, optional: true
  accepts_nested_attributes_for :context, :reject_if => proc { |attributes| attributes.all? { |key, value| key == "_destroy" || value.blank? || (value.is_a?(Hash) && value.values.all?(&:blank?)) } }
  validates_associated :context

  belongs_to :material, optional: true
  accepts_nested_attributes_for :material, reject_if: :all_blank
  validates_associated :material

  belongs_to :taxon, optional: true
  accepts_nested_attributes_for :taxon, reject_if: :all_blank
  validates_associated :taxon

  has_many :c14s
  has_many :typos

  has_paper_trail
end
