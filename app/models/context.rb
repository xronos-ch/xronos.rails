# == Schema Information
#
# Table name: contexts
# Database name: primary
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_id           :integer
#
# Indexes
#
#  index_contexts_on_name     (name)
#  index_contexts_on_site_id  (site_id)
#

class Context < ApplicationRecord
  include Versioned

  FUNCTIONAL_CLASSIFICATION_SUGGESTION_PATTERN =
    "settlement|habitation|occupation|dwelling|village|house|domestic|" \
      "burial|cemetery|grave|funerary|tomb|necropolis|" \
      "hoard|depot|deposit|" \
      "production|workshop|kiln|craft|industrial|metallurgy|mine|mining|" \
      "ritual|ceremonial|cult|sanctuary|temple|shrine|" \
      "palaeoenvironmental|paleoenvironmental|environmental|off.?site|core|peat|lake|sediment|" \
      "natural|geological"

  validates :name, presence: true

  belongs_to :site
  accepts_nested_attributes_for :site, :reject_if => proc { |attributes| attributes.all? { |key, value| key == "_destroy" || value.blank? || (value.is_a?(Hash) && value.values.all?(&:blank?)) } }
  validates_associated :site

  has_many :samples, dependent: :destroy

  has_many :c14s, through: :samples
  has_many :typos, through: :samples

  has_many :functional_classifications,
           as: :assignable,
           dependent: :destroy

  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = [ :missing_functional_classification ]

  scope :with_functional_classification_suggestions, -> {
    joins(site: :site_types)
      .left_outer_joins(:functional_classifications)
      .where(functional_classifications: { id: nil })
      .where(
        "LOWER(site_types.name) ~ ?",
        FUNCTIONAL_CLASSIFICATION_SUGGESTION_PATTERN
      )
      .distinct
  }

  def self.label
    "context"
  end

  def suggested_functional_classification_category
    return nil if site.blank? || !site.respond_to?(:site_types)

    site_type_names = site.site_types
                          .map { |site_type| site_type.name.to_s.downcase }
                          .join(" ")

    category_name =
      case site_type_names
      when /settlement|habitation|occupation|dwelling|village|house|domestic/
        "settlement"
      when /burial|cemetery|grave|funerary|tomb|necropolis/
        "burial"
      when /hoard|depot|deposit/
        "hoard"
      when /production|workshop|kiln|craft|industrial|metallurgy|mine|mining/
        "production"
      when /ritual|ceremonial|cult|sanctuary|temple|shrine/
        "ritual_ceremonial"
      when /palaeoenvironmental|paleoenvironmental|environmental|off.?site|core|peat|lake|sediment/
        "palaeoenvironmental"
      when /natural|geological/
        "natural"
      else
        nil
      end

    FunctionalClassificationCategory.find_by(name: category_name)
  end

  def suggested_confidence
    "possible"
  end

  def functional_classification_suggestion_available?
    functional_classifications.blank? &&
      suggested_functional_classification_category.present? &&
      suggested_confidence.present?
  end

  # Issues

  scope :missing_functional_classification, -> {
    joins(:c14s)
      .left_outer_joins(:functional_classifications)
      .where(functional_classifications: { id: nil })
      .distinct
  }

  def missing_functional_classification?
    c14s.exists? && functional_classifications.blank?
  end

end
