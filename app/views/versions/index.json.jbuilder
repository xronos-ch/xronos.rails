json.pagination do
  json.page @pagy.page
  json.per_page @pagy.limit
  json.total_count @pagy.count
  json.total_pages (@pagy.count.to_f / @pagy.limit).ceil
  json.next_page(@pagy.page * @pagy.limit < @pagy.count ? @pagy.page + 1 : nil)
  json.previous_page(@pagy.page > 1 ? @pagy.page - 1 : nil)
end

json.filters @filters.to_h.reject { |_, value| value.blank? }

json.changes @versions do |entry|
  is_supersession = entry.is_a?(SupersessionEvent)

  json.id entry.id
  json.entry_type(is_supersession ? "supersession" : "version")
  json.created_at entry.created_at.iso8601(6)

  if is_supersession
    json.record_type entry.superseded_type
    json.record_id entry.superseded_id
    json.event entry.event_type
    json.comment entry.comment

    json.changes({})

    json.superseded_by do
      json.record_type entry.superseded_by_type
      json.record_id entry.superseded_by_id
    end
  else
    json.record_type entry.item_type
    json.record_id entry.item_id
    json.event entry.event
    json.comment entry.revision_comment

    json.changes((entry.object_changes || {}).except("updated_at"))
    json.superseded_by nil
  end

  user_id = is_supersession ? entry.whodunnit_user_id : entry.whodunnit
  user = @contributors[user_id.to_s]

  if user
    json.contributor do
      json.id user.id
      json.name user.user_profile&.full_name
    end
  else
    json.contributor nil
  end
end
