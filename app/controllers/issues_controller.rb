class IssuesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  layout "curate"

  def index
  end

  private

  def issues
    # override, e.g. Site.issues
    []
  end

  def issue_param
    issue = params.fetch(:issue, nil).to_s
    return nil if issue.blank?
    issue if issue.in?(issues.map(&:to_s))
  end

  def issue_relation_for(model_class)
    return model_class.all unless issue_param.present?
    issue_scope = model_class.issues.index_by(&:to_s)[issue_param]
    return model_class.none unless issue_scope
    model_class.public_send(issue_scope)
  end
end