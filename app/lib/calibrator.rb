##
# calibrator.rb
#
# Ruby wrapper for calibrator: https://github.com/ISAAKiel/calibrator, a
# command-line radiocarbon calibration tool.
#
# Expects a binary version of calibrator in ./vendor/calibrator/bin/
module Calibrator

  class Calibration
    attr_reader :c14_age, :c14_error, :prob_dist, :hpd_intervals
    
    def initialize(c14_age, c14_error, c14_curve)
      @c14_age = c14_age
      @c14_error = c14_error
      @c14_curve = c14_curve

      cal_json = Calibrator.calibrate(c14_age, c14_error) # TODO: c14_curve
      unless cal_json.blank?
        @prob_dist = cal_json["date"]["bp"]
          .zip(cal_json["date"]["probabilities"])
          .map{ |k, v| { age: k, pdens: v } }
        @hpd_intervals = cal_json["date"]["sigma_ranges"]
      end
    end
    
  end

  class SumCalibration
    # TODO: https://github.com/xronos-ch/xronos.rails/issues/328
  end

  def self.calibrate(age, error)
    JSON.parse(`cd vendor/calibrator/bin/; ./#{bin} -b #{age} -s #{error} -r`)
  end

  private

  def self.bin
    if RUBY_PLATFORM =~ /darwin/
      "calibrator_mac"
    elsif RUBY_PLATFORM =~ /linux/
      "calibrator_linux"
    else
      raise "No calib binary for #{RUBY_PLATFORM}"
    end
  end

end
