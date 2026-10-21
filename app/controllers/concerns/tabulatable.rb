module Tabulatable
  extend ActiveSupport::Concern

  included do # instance methods
    private
    def index_csv_template
      path = "app/views/#{controller_name}/index.csv"
      if File.exist?(path)
        File.open(path).read
      else
        nil
      end
    end

    def validate_csv_params!
      disallowed = params.keys.select { |k|
        k.to_s.end_with?('_page', '_order', '_order_by')
      }

      if disallowed.any?
        Rails.logger.warn "CSV request rejected - disallowed params: #{disallowed.join(', ')}"
        head :bad_request
      end
    end
  end

  class_methods do
  end

end
