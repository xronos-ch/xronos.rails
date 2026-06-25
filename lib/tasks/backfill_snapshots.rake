namespace :xronos do
  desc "Backfill ActiveSnapshot snapshots for existing Site PaperTrail versions"
  task backfill_snapshots: :environment do
    total = 0
    done = 0
    skipped = 0
    failed = 0

    Site.find_each do |site|
      versions = site.versions.order(:created_at, :id).to_a
      next if versions.empty?

      peripherals = collect_peripherals(site)

      versions.each do |version|
        if version.snapshot_id.present?
          skipped += 1
          next
        end

        begin
          snapshot = build_version_snapshot(site, version, peripherals)
          version.update_column(:snapshot_id, snapshot.id)
          done += 1
        rescue => e
          Rails.logger.warn "Backfill failed for Site##{site.id} v#{version.id}: #{e.message}"
          failed += 1
        end
        total += 1
      end
    end

    puts "Done. #{total} processed, #{done} snapshotted, #{skipped} skipped, #{failed} failed."
  end
end

def collect_peripherals(site)
  site_names = {}
  lod_links = {}

  # Current peripherals
  site.site_names.each { |r| site_names[r.id] = r.versions.order(:created_at).to_a }
  site.lod_links.each { |r| lod_links[r.id] = r.versions.order(:created_at).to_a }

  # Deleted SiteNames (via PaperTrail)
  deleted_site_name_ids(site.id).each do |id|
    next if site_names.key?(id)
    site_names[id] = PaperTrail::Version.where(item_type: "SiteName", item_id: id)
      .order(:created_at).to_a
  end

  # Deleted LodLinks (via PaperTrail)
  deleted_lod_link_ids(site.id).each do |id|
    next if lod_links.key?(id)
    lod_links[id] = PaperTrail::Version.where(item_type: "LodLink", item_id: id)
      .order(:created_at).to_a
  end

  { site_names: site_names, lod_links: lod_links }
end

def deleted_site_name_ids(site_id)
  via_object = PaperTrail::Version.where(item_type: "SiteName")
    .where_object(site_id: site_id)
    .distinct
    .pluck(:item_id)

  via_changes = PaperTrail::Version.where(item_type: "SiteName")
    .where_object_changes(site_id: [site_id])
    .distinct
    .pluck(:item_id)

  (via_object + via_changes).uniq
end

def deleted_lod_link_ids(site_id)
  via_object = PaperTrail::Version.where(item_type: "LodLink")
    .where_object(linkable_id: site_id, linkable_type: "Site")
    .distinct
    .pluck(:item_id)

  via_changes = PaperTrail::Version.where(item_type: "LodLink")
    .where_object_changes(linkable_id: [site_id])
    .where_object_changes(linkable_type: ["Site"])
    .distinct
    .pluck(:item_id)

  (via_object + via_changes).uniq
end

def peripheral_state_at(klass, versions, time)
  active = versions.select { |v| v.created_at <= time }
  return nil if active.empty?

  latest = active.max_by(&:created_at)
  return nil if latest.event == "destroy"

  record = latest.reify(dup: true) || klass.new
  if latest.event != "destroy" && latest.changeset.any?
    record.assign_attributes(latest.changeset.transform_values(&:last))
  end
  record.id = latest.item_id
  record
end

def build_version_snapshot(site, version, peripherals)
  time = version.created_at

  # Reconstruct Site state at this version
  site_state = if version.event == "create"
    record = Site.new
    version.changeset.each { |attr, (_, new_val)| record[attr] = new_val if record.respond_to?("#{attr}=") }
    record.id = version.item_id
    record
  else
    record = version.reify(dup: true)
    if record && version.event != "destroy"
      record.assign_attributes(version.changeset.transform_values(&:last))
    end
    record
  end

  # Reconstruct peripheral states
  snapshot = site.snapshots.build(
    identifier: "backfill:s#{site.id}:v#{version.id}",
    metadata: { source: :backfill, version_id: version.id }
  )

  snapshot.build_snapshot_item(site_state) if site_state

  peripherals[:site_names].each_value do |pvs|
    p_state = peripheral_state_at(SiteName, pvs, time)
    next unless p_state
    snapshot.build_snapshot_item(p_state, child_group_name: "site_names")
  end

  peripherals[:lod_links].each_value do |pvs|
    p_state = peripheral_state_at(LodLink, pvs, time)
    next unless p_state
    snapshot.build_snapshot_item(p_state, child_group_name: "lod_links")
  end

  snapshot.save!
  snapshot.snapshot_items.each(&:save!)
  snapshot
end
