class Issues::C14sController < IssuesController
  load_and_authorize_resource

  # GET /issues/c14s/:issue
  def index
    @c14s = issue_relation_for(C14)

    if params.has_key?(:search)
      @c14s = @c14s.search params[:search]
    end

    if params.has_key?(:c14s_order_by)
      order = { params[:c14s_order_by] => params.fetch(:c14s_order, "asc") }
    else
      order = :id
    end
    @c14s = @c14s.reorder(order)

    respond_to do |format|
      format.html do
        @pagy, @c14s = pagy(:offset, @c14s)
        @duplicate_ids = matching_ids(@c14s)
      end
    end
  end

  private

  def matching_ids(records)
    keys = records.filter_map(&:potential_duplicate_key).uniq
    return {} if keys.empty?

    fields = C14.potential_duplicates_attrs
    matches = C14.where(fields => keys).reorder(:id).pluck(*fields, :id)
    matches.group_by { |row| row.first(fields.length) }.transform_values { |rows| rows.map(&:last) }
  end

  def issues
    C14.issues
  end

end
