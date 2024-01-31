module C14sHelper
  def cal_plot(cal)
    return nil unless cal.present?
    Vega.lite
      .config(padding: 0)
      .background(nil)
      .view(strokeWidth: 0, fill: "")
      .data(cal.prob_dist)
      .mark(type: "area", color: "rgb(60, 59, 57)", opacity: 0.9, tooltip: true, "line": {strokeWidth: 4, color: "rgb(60, 59, 57)"}, interpolate: "monotone")
      .encoding(
        x: {field: "age", type: "quantitative", title: "cal BP",
            axis: {grid: true, gridColor: "rgb(209, 215, 219)", tickMinStep: 50, labelColor: "#212F1F", titleColor: "#212F1F" }},
    y: {field: "pdens", type: "quantitative",
        axis: nil },
      )
  end

  def format_hd_interval(hdi)
    "#{hdi['begin']}–#{hdi['end']}"
  end

  def c14_curve_ref(c14_curve)
    # TODO: make proper references (should be part of seed data)
    # https://github.com/xronos-ch/xronos.rails/issues/330
    case c14_curve
    when "IntCal20"
      "Reimer et al. 2020"
    when "SHCal20"
      "Hogg et al. 2020"
    when "Marine20"
      "Heaton et al. 2020"
    else
      nil
    end
  end

end
