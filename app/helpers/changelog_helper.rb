module ChangelogHelper
  def combined_changelog(item)
    versions = item.versions.includes(:item).to_a
    events = item.respond_to?(:supersession_events) \
      ? item.supersession_events.includes(:whodunnit_user, :superseded_by).to_a \
      : []
    (versions + events).sort_by(&:created_at)
  end
end
