class IssuesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  layout "curate"

  def index
  end

  private

  def issues
    # override, e.g. Site.issues
  end

  def issue_param
    issue = params.fetch(:issue, nil)
    return issue if issue.present? and issue.in?(issues.to_s)
  end


end
