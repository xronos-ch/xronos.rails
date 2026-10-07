# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/BlockLength

# Backfills ActiveSnapshot snapshots for historical PaperTrail versions.
#
# Known limitations of historical data:
# - Citations (and the site_types_sites join) have no PaperTrail history and
#   no timestamps, so their state at past versions is unknowable. Decision
#   (2026-10): EXCLUDE them from backfilled snapshots rather than risk
#   asserting they existed before they were actually added. They are captured
#   in snapshots from the first post-deploy version onwards.
# - Create versions recorded by older PaperTrail have nil object_changes;
#   state is reconstructed from the next version's object, or the current
#   record if the create is the only version.
#
# Usage:
#   bin/rails xronos:backfill_snapshots                 # full run
#   MODELS=Site,Sample bin/rails xronos:backfill_snapshots
#   MODELS=Site LIMIT=500 bin/rails xronos:backfill_snapshots  # dry run

namespace :xronos do
  desc 'Backfill ActiveSnapshot snapshots for all versioned models'
  task backfill_snapshots: :environment do
    $stdout.sync = true # unbuffered output so progress can be monitored via log files
    Rails.application.eager_load!

    models_with_snapshots = ApplicationRecord.descendants.select do |model|
      model.respond_to?(:snapshot_children_proc) && model.snapshot_children_proc.present?
    end

    if ENV['MODELS'].present?
      allowed = ENV['MODELS'].split(',').map(&:strip)
      models_with_snapshots &= allowed.map(&:constantize)
    end
    limit = ENV['LIMIT']&.to_i

    model_names = models_with_snapshots.map(&:name).join(', ')
    puts "Found #{models_with_snapshots.size} models with snapshot_peripherals: #{model_names}"
    puts "LIMIT=#{limit} records per model" if limit

    totals = { total: 0, done: 0, skipped: 0, failed: 0 }

    models_with_snapshots.each do |model|
      puts "\nProcessing #{model.name}..."
      result = backfill_model(model, limit: limit)
      totals.each_key { |k| totals[k] += result[k] }
      puts "#{model.name}: #{result[:total]} processed, #{result[:done]} snapshotted, " \
           "#{result[:skipped]} skipped, #{result[:failed]} failed"
    end

    puts "\n=== Summary ==="
    puts "Total: #{totals[:total]} processed, #{totals[:done]} snapshotted, " \
         "#{totals[:skipped]} skipped, #{totals[:failed]} failed."
  end
end

def backfill_model(model, limit: nil)
  counts = { total: 0, done: 0, skipped: 0, failed: 0 }
  started_at = Time.current

  # unscoped: superseded records (hidden by Supersedable's default_scope)
  # keep their permalinks, so their histories still need snapshots.
  scope = model.unscoped
  scope = scope.where(id: scope.limit(limit).select(:id)) if limit

  scope.find_each.with_index do |record, index|
    versions = PaperTrail::Version.where(item_type: model.name, item_id: record.id).order(:created_at, :id).to_a
    next if versions.empty?

    peripherals = collect_peripherals(record, versions)

    versions.each do |version|
      if version.snapshot_id.present?
        counts[:skipped] += 1
        next
      end

      begin
        snapshot = build_version_snapshot(record, version, versions, peripherals)
        version.update_column(:snapshot_id, snapshot.id)
        counts[:done] += 1
      rescue StandardError => e
        Rails.logger.warn "Backfill failed for #{model.name}##{record.id} v#{version.id}: #{e.class} #{e.message}"
        counts[:failed] += 1
      end
      counts[:total] += 1
    end

    report_progress(model, index + 1, counts, started_at) if ((index + 1) % 1000).zero?
  end

  counts
end

def report_progress(model, records, counts, started_at)
  elapsed = Time.current - started_at
  rate = (counts[:total] / elapsed).round(1)
  puts "  #{model.name}: #{records} records, #{counts[:total]} versions, #{rate} versions/s, #{counts[:failed]} failed"
end

# Legacy PaperTrail item_types: models whose table was renamed after
# versions had already been recorded under the old class name.
LEGACY_ITEM_TYPES = { 'LinkedResource' => %w[LodLink] }.freeze

def version_item_types(klass)
  [klass.name] + LEGACY_ITEM_TYPES.fetch(klass.name, [])
end

# One cheap per-class check: if a peripheral class has no PaperTrail
# versions at all (e.g. Citation, FunctionalClassification), its historical
# state is unknowable and it is excluded from all snapshots (see header).
def class_versioned?(klass)
  @class_versioned ||= {}
  @class_versioned[klass.name] ||= PaperTrail::Version.where(item_type: version_item_types(klass)).exists?
end

def collect_peripherals(record, versions)
  result = {}

  return result unless record.class.respond_to?(:snapshot_children_proc) && record.class.snapshot_children_proc

  assoc_hash = record.instance_exec(&record.class.snapshot_children_proc)
  assoc_names = assoc_hash.keys

  assoc_names.each do |assoc_name|
    assoc = record.class.reflect_on_association(assoc_name)
    next unless assoc
    next unless class_versioned?(assoc.klass)

    result[assoc_name] = if assoc.macro == :belongs_to
                           collect_shared_peripheral(record, assoc, versions)
                         else
                           collect_owned_peripheral(record, assoc)
                         end
  end

  result
end

# Returns { peripheral_id => { versions: [...], current: record_or_nil } }
def collect_owned_peripheral(record, assoc)
  peripheral_class = assoc.klass
  foreign_key = assoc.foreign_key.to_s
  peripherals = {}

  Array(record.send(assoc.name)).each do |p|
    peripherals[p.id] = {
      versions: peripheral_versions(peripheral_class, p.id),
      current: p
    }
  end

  find_deleted_peripheral_ids(peripheral_class, foreign_key, record.id).each do |id|
    next if peripherals.key?(id)

    peripherals[id] = { versions: peripheral_versions(peripheral_class, id), current: nil }
  end

  peripherals
end

def collect_shared_peripheral(record, assoc, versions)
  peripheral_class = assoc.klass
  peripherals = {}

  current = record.send(assoc.name)
  if current
    peripherals[current.id] = {
      versions: peripheral_versions(peripheral_class, current.id),
      current: current
    }
  end

  # Historical peripherals: extract foreign keys from the parent's own
  # versions (both object and object_changes).
  extract_historical_foreign_keys(versions, assoc.foreign_key.to_s).each do |id|
    next if peripherals.key?(id)

    peripherals[id] = { versions: peripheral_versions(peripheral_class, id), current: nil }
  end

  peripherals
end

# Shared peripherals (Material, Taxon, SiteType) are referenced by many
# parent records; their versions never change during the run, so cache them
# per (class, id) to avoid re-querying for every referencing record.
def peripheral_versions(peripheral_class, id)
  @peripheral_versions_cache ||= {}
  @peripheral_versions_cache[[peripheral_class.name, id]] ||=
    PaperTrail::Version.where(item_type: version_item_types(peripheral_class), item_id: id).order(:created_at, :id).to_a
end

def find_deleted_peripheral_ids(peripheral_class, foreign_key, parent_id)
  via_object = PaperTrail::Version.where(item_type: version_item_types(peripheral_class))
                                  .where('object LIKE ?', "%#{foreign_key}: #{parent_id}%")
                                  .distinct
                                  .pluck(:item_id)

  via_changes = PaperTrail::Version.where(item_type: version_item_types(peripheral_class))
                                   .where('object_changes::text LIKE ?', "%#{foreign_key}%#{parent_id}%")
                                   .distinct
                                   .pluck(:item_id)

  (via_object + via_changes).uniq
end

def extract_historical_foreign_keys(versions, foreign_key)
  ids = Set.new

  versions.each do |version|
    obj = parse_version_object(version.object)
    ids << obj[foreign_key] if obj && obj[foreign_key].present?

    changes = parse_object_changes(version.object_changes)
    if changes[foreign_key].is_a?(Array)
      changes[foreign_key].each { |v| ids << v if v.present? }
    elsif changes[foreign_key].present?
      ids << changes[foreign_key]
    end
  end

  ids.to_a
end

# Reconstructs the state of an item at a given PaperTrail version.
#
# Handles three quirks of historical PaperTrail data:
# - create versions may have nil object_changes (values were not recorded);
#   fall back to the next version's pre-change state, or the current record
#   if the create is the item's only version.
# - destroy versions: use the pre-destroy object as-is; object_changes for
#   destroys nil out every attribute and must not be applied.
# - object may be YAML (String) or a Hash; object_changes may be JSON
#   (String) or a Hash (jsonb).
#
# `all_versions` must contain every version of the item, ordered by id.
# `fallback_record` is used when no later version exists (typically the
# current record loaded from the database).
def reconstruct_state(klass, version, all_versions, fallback_record: nil)
  record = klass.new
  record.id = version.item_id

  case version.event
  when 'create'
    changes = parse_object_changes(version.object_changes)
    if changes.present?
      apply_changes(record, changes)
    else
      applied = apply_object(record, next_version_object(version, all_versions))
      apply_current_state(record, fallback_record) unless applied
    end
  when 'destroy'
    apply_object(record, parse_version_object(version.object))
  else # update, touch
    apply_object(record, parse_version_object(version.object))
    apply_changes(record, parse_object_changes(version.object_changes))
  end

  record
end

# Classes known to appear in serialized version objects: BigDecimal
# (decimal columns like lat/lng and sample positions), TimeWithZone/
# TimeZone (timestamps), Symbol. Note PaperTrail's own safe_load config
# (ActiveRecord.yaml_column_permitted_classes = [Symbol]) is too strict
# to read this data — even version.reify fails on it.
YAML_PERMITTED_CLASSES = [Symbol, BigDecimal, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone].freeze

def parse_version_object(raw)
  return nil if raw.nil?
  return raw unless raw.is_a?(String)

  YAML.safe_load(raw, permitted_classes: YAML_PERMITTED_CLASSES, aliases: true)
end

def parse_object_changes(raw)
  return {} if raw.nil?

  raw.is_a?(String) ? JSON.parse(raw) : raw
end

def apply_object(record, obj)
  return false if obj.blank?

  obj.each { |attr, val| record[attr] = val if record.respond_to?("#{attr}=") }
  true
end

def apply_changes(record, changes)
  changes.each { |attr, (_, new_val)| record[attr] = new_val if record.respond_to?("#{attr}=") }
end

def next_version_object(version, all_versions)
  nxt = all_versions.find { |v| v.id > version.id }
  nxt && parse_version_object(nxt.object)
end

def apply_current_state(record, fallback_record)
  return unless fallback_record

  fallback_record.attributes.each { |attr, val| record[attr] = val if record.respond_to?("#{attr}=") }
end

def peripheral_state_at(klass, peripheral, time)
  versions = peripheral[:versions]
  active = versions.select { |v| v.created_at <= time }
  return nil if active.empty?

  latest = active.max_by(&:created_at)
  return nil if latest.event == 'destroy'

  reconstruct_state(klass, latest, versions, fallback_record: peripheral[:current])
end

def build_version_snapshot(record, version, all_versions, peripherals)
  time = version.created_at

  record_state = reconstruct_state(record.class, version, all_versions, fallback_record: record)

  snapshot = record.snapshots.build(
    identifier: "backfill:#{record.class.name.underscore}:#{record.id}:v#{version.id}",
    metadata: { source: :backfill, version_id: version.id }
  )

  snapshot.build_snapshot_item(record_state) if record_state

  peripherals.each do |assoc_name, per_state|
    peripheral_class = record.class.reflect_on_association(assoc_name).klass

    per_state.each do |peripheral_id, peripheral|
      p_state = peripheral_state_at(peripheral_class, peripheral, time)
      next unless p_state

      existing = snapshot.snapshot_items.find do |si|
        si.item_type == peripheral_class.name && si.item_id == peripheral_id
      end
      next if existing

      snapshot.build_snapshot_item(p_state, child_group_name: assoc_name.to_s)
    end
  end

  # Save snapshot first (without validating items; snapshot_id is assigned
  # to the items afterwards).
  snapshot.save!(validate: false)
  snapshot.snapshot_items.each do |si|
    si.snapshot_id = snapshot.id
    si.save!
  end

  snapshot
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/BlockLength
