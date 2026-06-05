# == Schema Information
#
# Table name: citations
#
#  id           :bigint           not null, primary key
#  citing_type  :string
#  citing_id    :bigint
#  reference_id :bigint
#
# Indexes
#
#  index_citations_on_citing                (citing_type,citing_id)
#  index_citations_on_citing_and_reference  (citing_type,citing_id,reference_id) UNIQUE
#  index_citations_on_reference_id          (reference_id)
#
class Citation < ApplicationRecord

  belongs_to :citing, polymorphic: true
  belongs_to :reference

  validates :reference,
            uniqueness: {
              scope: %i[citing_type citing_id],
              message: "has already been cited for this record"
            }

  acts_as_copy_target # enable CSV exports

  after_destroy :destroy_reference_if_orphaned

  def destroy_reference_if_orphaned
    reference.destroy_if_orphaned
  end

  def self.label
    "citation"
  end

  def self.icon
    "icons/citation.svg"
  end

end
