module Controlled

  extend ActiveSupport::Concern

  included do # instance methods
    attr_accessor :skip_control

    def controlled?
      # override
    end

    private

    def control
      # override
    end

  end

  class_methods do
    def controlled?
      true
    end
  end

end

