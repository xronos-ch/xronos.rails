class CalibratedDate
  attr_accessor :bpc, :probability
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  def persisted?
    false
  end
end

module C14sHelper
  include Pagy::Frontend
  def calibrator(c14)
    unless c14.bp.blank? | c14.std.blank?

    if RUBY_PLATFORM =~ /darwin/
      calib = JSON.parse(`cd vendor/calibrator/bin/; ./calibrator_mac -b #{c14.bp} -s #{c14.std} -r`)
    elsif RUBY_PLATFORM =~ /linux/
      calib = JSON.parse(`cd vendor/calibrator/bin/; ./calibrator_linux -b #{c14.bp} -s #{c14.std} -r`)
    end
    
    chart_data = calib["date"]["bp"].zip(calib["date"]["probabilities"]).map{|k, v| {bp: k, probability: v}}
    
    @bp_cal = capture do
      return_string = "can not be calculated"
      unless calib["date"]["sigma_ranges"].blank?
        return_string = ""
        calib["date"]["sigma_ranges"].each do |sigma_range|
          return_string << sigma_range["begin"].to_s + " - " + sigma_range["end"].to_s + "<br/>"
        end
      end
      return_string.html_safe
    end


    Vega.lite
    .config(padding: 0)
    .background(nil)
      .view(strokeWidth: 0, fill: "")
      .data(chart_data)
      .mark(type: "area", color: "#B99555", opacity: 0.9, tooltip: true, "line": {strokeWidth: 4, color: "#B99555"}, interpolate: "monotone")
      .encoding(
        x: {field: "bp", type: "quantitative", title: "cal BP",
          axis: {grid: true, gridColor: "#6C757D", tickMinStep: 50, labelColor: "#212F1F", titleColor: "#212F1F" }},
        y: {field: "probability", type: "quantitative",
            axis: nil },
      )
    end
  end
end
