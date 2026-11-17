# == Schema Information
#
# Table name: citations
# Database name: primary
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
FactoryBot.define do
  factory :citation do
    association :reference
    association :citing, factory: :site
  end
end

