##
# calibrator.rb
#
# Ruby wrapper for calibrator: https://github.com/ISAAKiel/calibrator, a
# command-line radiocarbon calibration tool.
#
# Expects a binary version of calibrator in ./vendor/calibrator/bin/
module Calibrator

  class Calibration
    attr_reader :c14_age, :c14_error, :prob_dist, :hd_intervals
    
    def initialize(c14_age, c14_error, c14_curve)
      @c14_age = c14_age
      @c14_error = c14_error
      @c14_curve = c14_curve

      cal_json = Calibrator.calibrate(c14_age, c14_error, c14_curve)
      unless cal_json.blank?
        @prob_dist = cal_json["date"]["bp"]
          .zip(cal_json["date"]["probabilities"])
          .map{ |k, v| { age: k, pdens: v } }
        @hd_intervals = cal_json["date"]["sigma_ranges"]
      end
    end
    
  end

  class SumCalibration
      attr_reader :c14_ages, :c14_errors, :prob_dist, :hd_intervals
      
      def initialize(c14_ages, c14_errors, c14_curve)
          @c14_ages = c14_ages
          @c14_errors = c14_errors
          @c14_curve = c14_curve
          
          cal_json = Calibrator.sum_calibrate(c14_ages, c14_errors, c14_curve)
          unless cal_json.blank?
              @prob_dist = cal_json["sum"]["bp"]
              .zip(cal_json["sum"]["probabilities"])
              .map{ |k, v| { age: k, pdens: v } }
              @hd_intervals = cal_json["sum"]["sigma_ranges"]
          end
      end
  end

  def self.calibrate(c14_age, c14_error, c14_curve)
    # TODO: c14_curve
    JSON.parse(`cd vendor/calibrator/bin/; ./#{calibrator_bin} -b #{c14_age} -s #{c14_error} -r`)
  end
  
  def self.sum_calibrate(c14_ages, c14_errors, c14_curve)
      
      # Initialize an empty hash
      result = {}

      # Iterate through the bp array
      c14_ages.each_with_index do |value, index|
        key = "date#{index + 1}"
        result[key] = {
          "bp" => value,
          "std" => c14_errors[index]
        }
      end

      # Convert the hash to JSON
      json_object = result.to_json
      
      puts json_object
        
      JSON.parse(`cd vendor/calibrator/bin/; ./#{calibrator_bin} -j '#{json_object}' --sum -r`)
  end

  private

  def self.calibrator_bin
    if RUBY_PLATFORM =~ /darwin/
      "calibrator_mac"
    elsif RUBY_PLATFORM =~ /linux/
      "calibrator_linux"
    else
      raise "No calib binary for #{RUBY_PLATFORM}"
    end
  end

end
