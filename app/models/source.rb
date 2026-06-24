# == Schema Information
#
# Table name: sources
# Database name: primary
#
#  id            :bigint           not null, primary key
#  access_date   :date
#  file_manifest :jsonb
#  license       :string
#  name          :string           not null
#  notes         :text
#  path          :text
#  source_url    :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_sources_on_name_and_version  (name,version) UNIQUE WHERE (version IS NOT NULL)
#
class Source < ApplicationRecord
  has_many :imports, dependent: :restrict_with_error

  validates :name, presence: true
  validates :name, uniqueness: { scope: :version }, if: :version?

  def label
    version? ? "#{name} (#{version})" : name
  end
end
