# == Schema Information
#
# Table name: imports
# Database name: primary
#
#  id              :bigint           not null, primary key
#  error           :text
#  records_created :jsonb
#  records_updated :jsonb
#  success         :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  source_id       :bigint           not null
#
# Indexes
#
#  index_imports_on_source_id  (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (source_id => sources.id)
#
class Import < ApplicationRecord
  belongs_to :source

  validates :source, presence: true

  def records_created_total
    records_created.values.sum
  end

  def records_updated_total
    records_updated.values.sum
  end

  def summary
    created = records_created.map { |k, v| "#{v} #{k}" }.join(", ")
    updated = records_updated.map { |k, v| "#{v} #{k}" }.join(", ")
    parts = ["#{source.label}: #{created} created"]
    parts << "#{updated} updated" unless updated.blank?
    parts.join(", ")
  end
end
