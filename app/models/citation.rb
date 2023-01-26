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
#  index_citations_on_citing        (citing_type,citing_id)
#  index_citations_on_reference_id  (reference_id)
#
class Citation < ApplicationRecord

  include Versioned

  belongs_to :citing, polymorphic: true
  belongs_to :reference

end
