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

  def self.register(name:, version:, path:, source_url: nil, license: nil, access_date: Date.current, notes: nil)
    current_manifest = Dir["#{path}/*.csv"].to_h { |f|
      [File.basename(f), Digest::SHA256.hexdigest(File.read(f))]
    }

    source = find_or_create_by!(name: name, version: version) do |s|
      s.path = path
      s.file_manifest = current_manifest
      s.source_url = source_url
      s.license = license
      s.access_date = access_date
      s.notes = notes
    end

    if source.persisted?
      if source.path != path
        source.update!(path: path)
      end

      if source.file_manifest != current_manifest
        abort <<~MSG
          Files for '#{name} (#{version})' have changed since last import.
          To import updated data, register a new version and re-run this task.
        MSG
      end
    end

    source
  end

  def label
    version? ? "#{name} (#{version})" : name
  end
end
