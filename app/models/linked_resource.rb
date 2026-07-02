# == Schema Information
#
# Table name: linked_resources
# Database name: primary
#
#  id            :bigint           not null, primary key
#  data          :jsonb
#  linkable_type :string           not null
#  source        :string           not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  external_id   :string           not null
#  linkable_id   :bigint           not null
#
# Indexes
#
#  index_linked_resources_on_linkable_and_source            (linkable_type,linkable_id,source) UNIQUE
#  index_linked_resources_on_linkable_type_and_linkable_id  (linkable_type,linkable_id)
#
class LinkedResource < ApplicationRecord
  include Turbo::Broadcastable

  # Each known source is a module under LinkedResource::Sources that
  # exposes an ATTRIBUTES constant and calls Source.register (self-
  # registration) when Zeitwerk loads the file. KNOWN_SOURCES is the
  # canonical list of source keys; iterating it triggers each module's
  # load, and we then assert the registration actually happened — so a
  # missing or misbehaving source module fails loudly at class-load time
  # rather than silently at use-time. The class body re-evaluates on
  # every Zeitwerk reload, so the registry stays populated through
  # dev-mode reloads without a separate to_prepare / after_initialize
  # hook in config/.
  KNOWN_SOURCES = %i[wikidata pleiades vici opencontext idai_gazetteer].freeze
  KNOWN_SOURCES.each do |key|
    Sources.const_get(key.to_s.camelize)
    next if Source.known?(key.to_s)

    raise "Known source :#{key} is not registered. Check that " \
      "app/models/linked_resource/sources/#{key}.rb defines module " \
      "LinkedResource::Sources::#{key.to_s.camelize} and calls " \
      "LinkedResource::Source.register(#{key.inspect}, **ATTRIBUTES)."
  end

  validates :source, presence: true
  validates :source, uniqueness: { scope: %i[linkable_type linkable_id] }

  validate :external_id_matches_source_pattern

  enum :status, { pending: 'pending', approved: 'approved' }

  belongs_to :linkable, polymorphic: true

  # Scopes for filtering matches
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }

  def external_url
    LinkedResource::Source.find(source)&.url_for(external_id)
  end

  private

  def external_id_matches_source_pattern
    source_obj = LinkedResource::Source.find(source)
    if source_obj.nil?
      errors.add(:source, 'is not a known linked resource source') and return if source.present?
    else
      return if source_obj.valid_id?(external_id)

      errors.add(:external_id, "does not match the expected format for #{source_obj.name}")
    end
  end
end
