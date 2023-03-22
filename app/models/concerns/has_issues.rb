module HasIssues

  extend ActiveSupport::Concern

  included do # instance methods
    def issues
      self.class.issues.filter do |issue|
        self.has_issue?(issue)
      end
    end

    def has_issue?(issue)
      self.send(append_?(issue))
    end

    private
    
    def append_?(issue)
      (issue.to_s + "?").to_sym
    end
  end

  class_methods do
    attr_accessor :issues

    def has_issues?
      true
    end
  end

end
