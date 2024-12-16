module DendrosHelper
  def ring_width_plot(dendro)
    return nil unless dendro.present? && dendro.measurements.present?

    Vega.lite
      .config(padding: 0)
      .background(nil)
      .view(strokeWidth: 0, fill: "")
      .data(JSON.parse(dendro.measurements.to_json))
      .mark(type: "line", color: "rgb(60, 59, 57)", tooltip: true, interpolate: "monotone")
      .encoding(
        x: {
          field: "year", type: "quantitative", title: "Year",
          axis: {grid: true, gridColor: "rgb(209, 215, 219)", tickMinStep: 10, labelColor: "#212F1F", titleColor: "#212F1F"}
        },
        y: {
          field: "value", type: "quantitative", title: "Ring Width (mm)",
          axis: {grid: true, gridColor: "rgb(209, 215, 219)", labelColor: "#212F1F", titleColor: "#212F1F"}
        }
      )
  end
end