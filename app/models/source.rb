# == Schema Information
#
# Table name: sources
# Database name: primary
#
#  id            :bigint           not null, primary key
#  file_manifest :jsonb
#  license       :string
#  name          :string           not null
#  notes         :text
#  path          :text
#  source_url    :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  reference_id  :bigint
#
# Indexes
#
#  index_sources_on_name_and_version  (name,version) UNIQUE WHERE (version IS NOT NULL)
#  index_sources_on_reference_id      (reference_id)
#
# Foreign Keys
#
#  fk_rails_...  (reference_id => references.id)
#
class Source < ApplicationRecord
  class ManifestMismatchError < StandardError; end

  belongs_to :reference, optional: true
  has_many :imports, dependent: :restrict_with_error

  validates :name, presence: true
  validates :name, uniqueness: { scope: :version }, if: :version?

  def self.register(name:, version:, path:, source_url: nil, license: nil, notes: nil)
    current_manifest = Dir.children(path).to_h { |basename|
      full = File.join(path, basename)
      [basename, File.file?(full) ? Digest::SHA256.file(full).hexdigest : nil]
    }.compact

    attributes = { path: path, source_url: source_url, license: license, notes: notes }
    return register_snapshot(name, current_manifest, **attributes) if version.nil?

    source = find_or_create_by!(name: name, version: version) do |s|
      s.assign_attributes(attributes)
      s.file_manifest = current_manifest
    end

    if source.persisted?
      if source.path != path
        source.update!(path: path)
      end

      if source.file_manifest != current_manifest
        raise ManifestMismatchError, <<~MSG
          Files for '#{name} (#{version})' have changed since last import.
          To import updated data, register a new version and re-run this task.
        MSG
      end
    end

    source
  end

  def self.register!(**kwargs)
    register(**kwargs)
  rescue ManifestMismatchError => e
    abort e.message
  end

  # Serialise imports of the same dataset even when they use different source snapshots.
  def self.with_import_lock(name)
    transaction(requires_new: true) do
      quoted_name = connection.quote(name)
      connection.execute("SELECT pg_advisory_xact_lock(hashtext('xronos source import'), hashtext(#{quoted_name}))")
      yield
    end
  end

  def self.register_snapshot(name, manifest, **attributes)
    with_import_lock(name) do
      find_or_create_by!(name: name, version: nil, file_manifest: manifest) do |source|
        source.assign_attributes(attributes)
      end
    end
  end
  private_class_method :register_snapshot

  def self.label
    "data source"
  end

  def label
    version? ? "#{name} (#{version})" : name
  end
end
