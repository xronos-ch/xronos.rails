module ChangelogHelper
  def combined_changelog(item)
    versions = item.versions.includes(:item).to_a
    events = item.respond_to?(:supersession_events) \
      ? item.supersession_events.includes(:whodunnit_user, :superseded_by).to_a \
      : []
    (versions + events).sort_by(&:created_at)
  end

  def version_peripheral_diff(version)
    return nil unless version.try(:snapshot_id).present?

    current = ActiveSnapshot::Snapshot.includes(:snapshot_items).find_by(id: version.snapshot_id)
    return nil unless current

    previous = PaperTrail::Version
      .where(item_type: version.item_type, item_id: version.item_id)
      .where.not(snapshot_id: nil)
      .where("created_at < ?", version.created_at)
      .reorder(created_at: :desc)
      .first

    if previous&.snapshot_id.present?
      from = ActiveSnapshot::Snapshot.includes(:snapshot_items).find_by(id: previous.snapshot_id)
      return nil unless from

      ActiveSnapshot::Snapshot.diff(from, current).map do |entry|
        si = current.snapshot_items.find { |item| item.item_id == entry[:item_id] && item.item_type == entry[:item_type] }
        si ||= from.snapshot_items.find { |item| item.item_id == entry[:item_id] && item.item_type == entry[:item_type] }
        entry.merge(child_group_name: si&.child_group_name)
      end
    else
      current.snapshot_items.map { |item|
        { action: :create, item_type: item.item_type, item_id: item.item_id, child_group_name: item.child_group_name, changes: item.object.transform_values { |v| [nil, v] } }
      }
    end
  rescue => e
    Rails.logger.warn "Snapshot diff failed for version #{version.id}: #{e.message}"
    nil
  end
end
