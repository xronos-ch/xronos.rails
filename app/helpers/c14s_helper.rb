module C14sHelper
  include Pagy::Frontend
  include DataTableHelper

  def calibrator(c14)
    return nil unless c14.bp.present? | c14.std.present?

    calib = Calibrator::Calibration.new(c14.bp, c14.std, :IntCal20)

    @bp_cal = capture do
      return_string = "can not be calculated"
      unless calib.hpd_intervals.blank?
        return_string = ""
        calib.hpd_intervals.each do |sigma_range|
          return_string << sigma_range["begin"].to_s + " - " + sigma_range["end"].to_s + "<br/>"
        end
      end
      return_string.html_safe
    end

    Vega.lite
      .config(padding: 0)
      .background(nil)
      .view(strokeWidth: 0, fill: "")
      .data(calib.prob_dist)
      .mark(type: "area", color: "rgb(60, 59, 57)", opacity: 0.9, tooltip: true, "line": {strokeWidth: 4, color: "rgb(60, 59, 57)"}, interpolate: "monotone")
      .encoding(
        x: {field: "age", type: "quantitative", title: "cal BP",
            axis: {grid: true, gridColor: "rgb(209, 215, 219)", tickMinStep: 50, labelColor: "#212F1F", titleColor: "#212F1F" }},
    y: {field: "pdens", type: "quantitative",
        axis: nil },
      )
  end

end
