module HasLinkedResourceIssues

  extend ActiveSupport::Concern

  included do # instance methods
    def linked_resource_issues
      self.class.linked_resource_issues.filter do |issue|
        self.has_linked_resource_issue?(issue)
      end
    end

    def has_linked_resource_issue?(issue)
      self.send(append_?(issue))
    end

    private

    def append_?(issue)
      (issue.to_s + "?").to_sym
    end
  end

  class_methods do
    attr_reader :linked_resource_issues

    def has_linked_resource_issues?
      true
    end
  end

end
