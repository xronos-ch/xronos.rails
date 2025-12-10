# == Schema Information
#
# Table name: lod_links
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
  include Versioned

  attr_reader :item

  validates :external_id, presence: true, numericality: { only_integer: true }
  validates :source, presence: true
  
  enum :status, { pending: "pending", approved: "approved" }

  belongs_to :linkable, polymorphic: true
  
  # Scopes for filtering matches
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  
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
