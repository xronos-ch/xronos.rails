# == Schema Information
#
# Table name: linked_resources
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
#  index_linked_resources_on_linkable_type_and_linkable_id       (linkable_type,linkable_id)
#  index_linked_resources_on_polymorphic_source_and_external_id  (linkable_type,linkable_id,source,external_id) UNIQUE
#
class LinkedResource < ApplicationRecord
  include Turbo::Broadcastable

  EXTERNAL_URL = {
    'Wikidata' => 'https://www.wikidata.org/wiki/'
  }.with_indifferent_access

  validates :external_id, presence: true, numericality: { only_integer: true }
  validates :source, presence: true
  validates :source, uniqueness: { scope: [:external_id, :linkable_type, :linkable_id] }

  enum :status, { pending: "pending", approved: "approved" }

  belongs_to :linkable, polymorphic: true

  # Scopes for filtering matches
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }

  def qcode
    "Q#{external_id}"
  end

  def external_url
    EXTERNAL_URL[source]&.then { |base| base + qcode }
  end

end
