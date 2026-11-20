module DendrosHelper
  def dendro_calendar_year(year)
    return na_value if year.nil?

    year.positive? ? "#{year} CE" : "#{1 - year} BCE"
  end

  def dendro_dating_status(dendro)
    return "Unknown" if dendro.is_anchored.nil?

    dendro.is_anchored? ? "Anchored" : "Floating"
  end

  def dendro_value_label(dendro)
    variable = Dendro::MEASUREMENT_VARIABLES.fetch(dendro.measurement_variable, "Value")
    dendro.measurement_unit.present? ? "#{variable} (#{dendro.measurement_unit})" : variable
  end

  def ring_width_plot(dendro)
    return if dendro.measurements.blank?

    segment = 0
    previous = nil
    points = dendro.series_points.map do |point|
      if previous && (point["position"] != previous["position"] + 1 || previous["value"].nil?)
        segment += 1
      end
      previous = point
      point.merge("segment" => segment)
    end

    x = if dendro.is_anchored?
          {
            field: "calendar_year", type: "quantitative", title: "Calendar year",
            axis: { tickMinStep: 1, labelExpr: "datum.value > 0 ? datum.value + ' CE' : (1 - datum.value) + ' BCE'" }
          }
        else
          { field: "position", type: "quantitative", title: "Series position", axis: { tickMinStep: 1 } }
        end

    Vega.lite
      .config(padding: 0)
      .background(nil)
      .view(strokeWidth: 0, fill: "")
      .data(points)
      .mark(type: "line", color: "rgb(60, 59, 57)", tooltip: true, point: true)
      .encoding(
        x: x.merge(scale: { zero: false }),
        y: { field: "value", type: "quantitative", title: dendro_value_label(dendro) },
        detail: { field: "segment", type: "nominal" }
      )
  end
end
