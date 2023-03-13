module Tabulatable
  extend ActiveSupport::Concern

  included do # instance methods
    private
    def index_csv_template
      path = "app/views/#{controller_name}/index.csv"
      if File.exists?(path)
        File.open(path).read
      else
        nil
      end
    end
  end

  class_methods do
  end

end
