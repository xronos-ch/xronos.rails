module Knowable

  extend ActiveSupport::Concern

  included do # instance methods
    def knowable?
      true
    end

    def known?
      # override
    end

    private

    def issue_if_unknown
      unknown_issue_class = self.class.unknown_issue_class
      unknown_issue_foreign_key = self.class.unknown_issue_foreign_key
      if known?
        unknown_issue_class.destroy_by(unknown_issue_foreign_key => id)
        return nil
      else
        unknown_issue_class.find_or_create_by(unknown_issue_foreign_key => id)
      end
    end
  end

  class_methods do
    def unknown_issue_class
      Issues.const_get("Unknown" + self.model_name.name)
    end

    def unknown_issue_foreign_key
      unknown_issue_class.reflections[self.model_name.param_key].foreign_key
    end
  end

end

