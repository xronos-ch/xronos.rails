module Supersedable

  extend ActiveSupport::Concern

  included do # instance methods
    def supersedable?
      true
    end

    def superseded?
      superseded_by.present?
    end
  end

  class_methods do
  end

end
