# == Schema Information
#
# Table name: citations
#
#  id           :integer          not null, primary key
#  reference_id :integer
#  citing_type  :string
#  citing_id    :integer
#
# Indexes
#
#  index_citations_on_citing        (citing_type,citing_id)
#  index_citations_on_reference_id  (reference_id)
#

class Citation < ApplicationRecord

  belongs_to :citing, polymorphic: true
  belongs_to :reference

  acts_as_copy_target # enable CSV exports

  def self.label
    "citation"
  end

  def self.icon
    "icons/citation.svg"
  end

end
