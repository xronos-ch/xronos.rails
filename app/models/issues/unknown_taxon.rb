# == Schema Information
#
# Table name: issues_unknown_taxons
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  taxon_id   :bigint           not null
#
# Indexes
#
#  index_issues_unknown_taxons_on_taxon_id  (taxon_id)
#
# Foreign Keys
#
#  fk_rails_...  (taxon_id => taxons.id)
#
class Issues::UnknownTaxon < ApplicationRecord
  belongs_to :taxon
end
