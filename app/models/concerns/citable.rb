module Citable
  extend ActiveSupport::Concern

  # Citation label for the default (admin) user. Brace-wrapped to
  # preserve as a single literal name in BibTeX (avoids the
  # "Team, X. R. O. N. O. S. C." splitting when parsed as a personal name).
  ADMIN_AUTHOR_LABEL = "{XRONOS Core Team}".freeze

  included do
    include Rails.application.routes.url_helpers
  end

  def citation
    BibTeX::Entry.new.tap do |e|
      e.type         = :dataset
      e.key          = citation_key
      e.author       = citation_author
      e.title        = citation_title
      e.date         = citation_date
      e.publisher    = citation_publisher
      e.url          = citation_url
      e.urldate      = citation_access_date
    end
  end

  def render_citation
    cp = CiteProc::Processor.new style: 'apa', format: 'html', locale: 'en'
    cp.import [citation.to_citeproc]
    Array.wrap(cp.render(:bibliography, id: citation_key)).join.html_safe
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  private

  def citation_key
    "xronos_#{model_name.singular}_#{id}"
  end

  def citation_author
    citation_contributors
  end

  # Author ordering is:
  # 1. Record creator, unless that is the default user
  # 2. Contributors except the creator and default user, alphabetically
  # 3. The default user (ADMIN_USER_ID)
  #
  # Contributors without a display name are omitted.
  def citation_contributors
    admin_id = ENV["ADMIN_USER_ID"].to_i
    ids = versions.collect(&:whodunnit).compact.map(&:to_i).uniq
    contributor_users = User.includes(:user_profile).where(id: ids).select(&:has_real_name?)

    admin = User.find_by(id: admin_id)
    creator_id = versions.where(event: "create").first&.whodunnit&.to_i

    creator = contributor_users.find { |u| u.id == creator_id && u.id != admin_id }
    others  = contributor_users - [ creator, admin ].compact

    ordered = []
    ordered << creator.display_name if creator
    ordered.concat others.sort_by { |u| u.display_name.downcase }.map(&:display_name)
    ordered << ADMIN_AUTHOR_LABEL if admin

    return "{XRONOS contributors}" if ordered.empty?

    ordered.join(" and ")
  end

  # Models should override to set a sensible title
  def citation_title
    "XRONOS #{model_name.singular} ##{id}"
  end

  def citation_date
    updated_at
  end
  
  def citation_publisher
    "XRONOS: An Open Data Infrastructure for Archaeological Chronology"
  end

  def citation_url
    polymorphic_url(self)
  end

  def citation_access_date
    Time.current
  end
  
end
