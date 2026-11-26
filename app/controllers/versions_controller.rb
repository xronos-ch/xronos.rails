class VersionsController < ApplicationController

  PUBLIC_RECORD_TYPES = %w[
    C14 C14Lab Context FunctionalClassification Reference Sample Site Taxon Typo
  ].freeze

  JSON_PAGE_SIZE = 1000

  PUBLIC_EVENT_TYPES = %w[create update destroy supersede restore].freeze

  before_action :prevent_indexing

  class PageOutOfRange < StandardError; end

  rescue_from PageOutOfRange do
    head :not_found
  end

  rescue_from ActionController::UnpermittedParameters do
    render plain: "Invalid changelog parameters", status: :bad_request
  end

  def index
    @filters = params
      .permit(:record_type, :event_type, :from, :to, :page, :format)
      .except(:page, :format)

    unless valid_filters? && valid_page?
      render plain: "Invalid changelog filters", status: :bad_request
      return
    end

    respond_to do |format|
      format.html { @pagy, @versions = pagy_changelog }
      format.json do
        @pagy, @versions = pagy_changelog(limit: JSON_PAGE_SIZE, preload: false)
        @contributors = changelog_contributors(@versions)
      end
    end
  end

  private

  def prevent_indexing
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end

  def valid_page?
    return true if params[:page].nil?

    params[:page].to_s.match?(/\A[1-9][0-9]{0,9}\z/)
  end

  def valid_filters?
    return false if @filters[:record_type].present? &&
      !PUBLIC_RECORD_TYPES.include?(@filters[:record_type])

    return false if @filters[:event_type].present? &&
      !PUBLIC_EVENT_TYPES.include?(@filters[:event_type])

    from = Date.iso8601(@filters[:from]) if @filters[:from].present?
    to = Date.iso8601(@filters[:to]) if @filters[:to].present?

    from.nil? || to.nil? || from <= to
  rescue Date::Error
    false
  end

  def changelog_sql
    versions = PaperTrail::Version
      .where(item_type: PUBLIC_RECORD_TYPES)

    events = SupersessionEvent
      .where(superseded_type: PUBLIC_RECORD_TYPES, superseded_by_type: PUBLIC_RECORD_TYPES)

    if @filters[:record_type].present?
      versions = versions.where(item_type: @filters[:record_type])
      events = events.where(superseded_type: @filters[:record_type])
    end

    if @filters[:event_type].present?
      versions = versions.where(event: @filters[:event_type])
      events = events.where(event_type: @filters[:event_type])
    end

    if @filters[:from].present?
      from = Date.iso8601(@filters[:from]).in_time_zone
      versions = versions.where(created_at: from..)
      events = events.where(created_at: from..)
    end

    if @filters[:to].present?
      to = Date.iso8601(@filters[:to]).next_day.in_time_zone
      versions = versions.where("created_at < ?", to)
      events = events.where("created_at < ?", to)
    end

    versions
      .select("id, 'Version' AS entry_type, created_at")
      .to_sql + " UNION ALL " +
      events
      .select("id, 'SupersessionEvent' AS entry_type, created_at")
      .to_sql

  end

  def pagy_changelog(limit: Pagy::DEFAULT[:limit], preload: true)
    union_sql = changelog_sql

    total = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) FROM (#{union_sql}) AS changelog"
    ).first['count'].to_i

    page = (params[:page] || 1).to_i
    raise PageOutOfRange if page > 1 && (page - 1) * limit >= total

    pagy = Pagy::Offset.new(count: total, page: params[:page] || 1, limit: limit, request: request)

    [pagy, changelog_entries(union_sql, pagy: pagy, preload: preload)]
  end

  def changelog_contributors(entries)
    user_ids = entries.filter_map do |entry|
      id = if entry.is_a?(SupersessionEvent)
             entry.whodunnit_user_id
           else
             entry.whodunnit
           end

      id.to_s.presence
    end.uniq

    User.where(id: user_ids)
        .includes(:user_profile)
        .index_by { |user| user.id.to_s }
  end

  def changelog_entries(union_sql, pagy:, preload: true)
    sql = <<~SQL
      SELECT entry_type, id
      FROM (#{union_sql}) AS changelog
      ORDER BY created_at DESC, entry_type ASC, id DESC
    SQL

    sql += " LIMIT #{pagy.limit} OFFSET #{pagy.offset}"

    rows = ActiveRecord::Base.connection.execute(sql)

    version_ids = rows.select { |r| r['entry_type'] == 'Version' }.map { |r| r['id'] }
    event_ids   = rows.select { |r| r['entry_type'] == 'SupersessionEvent' }.map { |r| r['id'] }

    versions = PaperTrail::Version.where(id: version_ids)
    events = SupersessionEvent.where(id: event_ids)

    if preload
      versions = versions.includes(:item)
      events = events.includes(:whodunnit_user, :superseded_by)
    end

    versions = versions.index_by(&:id)
    events = events.index_by(&:id)

    entries = rows.filter_map { |r|
      case r['entry_type']
      when 'Version' then versions[r['id']]
      when 'SupersessionEvent' then events[r['id']]
      end
    }

    entries
  end
end
