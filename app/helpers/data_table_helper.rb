module DataTableHelper
  def link_to_order_by(label, column, table = controller_name)
    if ordered_by?(column, table)
      new_params = request.parameters.merge(
        order_by_param(table) => column, 
        order_param(table) => next_direction(table)
      )
    else
      new_params = request.parameters.merge(
        order_by_param(table) => column, 
        order_param(table) => "asc"
      )
    end
    link_to label, new_params, data: { turbo_action: :advance }
  end

  def ordered_by?(column, table = controller_name)
    params.fetch(order_by_param(table), nil) == column.to_s
  end

  def order_indicator(table = controller_name)
    order = params.fetch(order_param(table), "asc")
    order == "asc" ? fa_icon("caret-down") : fa_icon("caret-up")
  end

  protected

  def order_by_param(table)
    (table.to_s + "_order_by")
  end

  def order_param(table)
    (table.to_s + "_order")
  end

  def next_direction(table = controller_name)
    params.fetch(order_param(table), nil) == "asc" ? "desc" : "asc"
  end

end
