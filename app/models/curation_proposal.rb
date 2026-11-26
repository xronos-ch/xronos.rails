# frozen_string_literal: true

# A candidate change awaiting a curator's decision.
# == Schema Information
#
# Table name: curation_proposals
# Database name: primary
#
#  id           :bigint           not null, primary key
#  evidence     :jsonb            not null
#  kind         :string           not null
#  subject_type :string           not null
#  target_key   :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  subject_id   :bigint           not null
#
# Indexes
#
#  index_curation_proposals_on_kind_and_id  (kind,id)
#  index_curation_proposals_on_target       (subject_type,subject_id,kind,target_key) UNIQUE
#
class CurationProposal < ApplicationRecord
  belongs_to :subject, polymorphic: true

  validates :kind, :target_key, presence: true
end
