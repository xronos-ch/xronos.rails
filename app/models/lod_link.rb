# == Schema Information
#
# Table name: lod_links
# Database name: primary
#
#  id            :bigint           not null, primary key
#  data          :jsonb
#  linkable_type :string           not null
#  source        :string           not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  external_id   :string           not null
#  linkable_id   :bigint           not null
#
# Indexes
#
#  index_lod_links_on_linkable_type_and_linkable_id  (linkable_type,linkable_id)
#  index_lod_links_on_source_and_external_id         (source,external_id) UNIQUE
#
class LodLink < ApplicationRecord
  include Turbo::Broadcastable

  attr_reader :item

  validates :external_id, presence: true, numericality: { only_integer: true }
  validates :source, presence: true
  
  enum :status, { pending: "pending", approved: "approved" }

  belongs_to :linkable, polymorphic: true, touch: true
  
  before_save :set_revision_comment_on_save, if: :linkable_is_site?
  before_destroy :set_revision_comment_on_destroy, if: :linkable_is_site?

  # Scopes for filtering matches
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }

  def self.label
    "external link"
  end

  private

  def linkable_is_site?
    linkable.is_a?(Site)
  end

  def set_revision_comment_on_save
    linkable.revision_comment = new_record? ? "Added #{self.class.label}." : "Changed #{self.class.label}."
  end

  def set_revision_comment_on_destroy
    linkable.revision_comment = "Removed #{self.class.label}."
  end
  
  def item
    @item ||= request_item
  end

  def request_item
    if source == "Wikidata"
      Rails.cache.fetch("wikidata_item_#{external_id}", expires_in: 24.hours) do
        WikidataItem.new(external_id)
      end
    end
  end

  def title
    item.present? ? item.label : qcode
  end

end
