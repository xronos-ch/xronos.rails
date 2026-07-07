class Curate::RecentChangesController < CurateController

  def index
    @pagy, @versions = pagy_changelog

    respond_to do |format|
      format.html
      format.json
    end
  end

  private

  def pagy_changelog
    union_sql = PaperTrail::Version
      .select("id, 'Version' AS entry_type, created_at")
      .to_sql + " UNION ALL " +
      SupersessionEvent
      .select("id, 'SupersessionEvent' AS entry_type, created_at")
      .to_sql

    total = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) FROM (#{union_sql}) AS changelog"
    ).first['count'].to_i

    pagy = Pagy.new(count: total, page: params[:page] || 1)

    rows = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT entry_type, id
      FROM (#{union_sql}) AS changelog
      ORDER BY created_at DESC
      LIMIT #{pagy.limit} OFFSET #{pagy.offset}
    SQL

    version_ids = rows.select { |r| r['entry_type'] == 'Version' }.map { |r| r['id'] }
    event_ids   = rows.select { |r| r['entry_type'] == 'SupersessionEvent' }.map { |r| r['id'] }

    versions = PaperTrail::Version.where(id: version_ids).index_by(&:id)
    events   = SupersessionEvent.where(id: event_ids)
                  .includes(:whodunnit_user, :superseded_by)
                  .index_by(&:id)

    entries = rows.filter_map { |r|
      case r['entry_type']
      when 'Version' then versions[r['id']]
      when 'SupersessionEvent' then events[r['id']]
      end
    }

    [pagy, entries]
  end
end
