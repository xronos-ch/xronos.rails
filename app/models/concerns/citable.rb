module Citable
  extend ActiveSupport::Concern

  # CSL name entry for the default (admin) user, representing the
  # project as a whole rather than an individual.
  ADMIN_AUTHOR_NAME = { "literal" => "XRONOS Core Team" }.freeze

  included do
    include Rails.application.routes.url_helpers
  end

  def citation
    {
      "id"        => citation_key,
      "type"          => "entry",
      "title"         => "#{citation_title} (#{self.class.label})",
      "author"        => citation_authors,
      "issued"        => citation_issued,
      "container-title" => citation_container_title,
      "URL"           => citation_url,
      "accessed"      => citation_accessed
    }
  end

  def render_citation
    cp = CiteProc::Processor.new style: 'apa', format: 'html', locale: 'en'
    cp.import [citation]
    Array.wrap(cp.render(:bibliography, id: citation_key)).join.html_safe
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  private

  def citation_key
    "xronos_#{model_name.singular}_#{id}"
  end

  # Author ordering:
  # 1. Record creator, unless that is the default user
  # 2. Contributors except the creator and default user, alphabetically
  # 3. The default user (ADMIN_USER_ID)
  #
  # Contributors without a display name are omitted.
  def citation_authors
    admin_id = ENV["ADMIN_USER_ID"].to_i
    ids = versions.collect(&:whodunnit).compact.map(&:to_i).uniq
    contributor_users = User.includes(:user_profile).where(id: ids).select(&:has_real_name?)

    admin = User.find_by(id: admin_id)
    creator_id = versions.where(event: "create").first&.whodunnit&.to_i

    creator = contributor_users.find { |u| u.id == creator_id && u.id != admin_id }
    others  = contributor_users - [ creator, admin ].compact

    names = []
    names << csl_name(creator) if creator
    names.concat others.sort_by { |u| u.display_name.downcase }.map { |u| csl_name(u) }
    names << ADMIN_AUTHOR_NAME if admin

    return [{ "literal" => "XRONOS contributors" }] if names.empty?

    names
  end

  # Convert a User's display_name to a CSL personal-name entry, using
  # BibTeX's name parser to handle particles (e.g. "von Humboldt"),
  # inverted forms ("Humboldt, Alexander"), and mononyms ("Madonna").
  def csl_name(user)
    parsed = BibTeX::Names.parse(user.display_name.to_s.strip).first
    return { "family" => user.display_name.to_s.strip } if parsed.nil?

    csl = {}
    csl["family"] = parsed.family if parsed.family
    csl["given"] = parsed.given if parsed.given
    csl["non-dropping-particle"] = parsed.prefix if parsed.prefix
    csl["suffix"] = parsed.suffix if parsed.suffix
    csl
  end

  # Models should override to set a sensible title
  def citation_title
    "XRONOS #{model_name.singular} ##{id}"
  end

  def citation_issued
    { "date-parts" => [[citation_date.year, citation_date.month, citation_date.day]] }
  end

  def citation_date
    updated_at
  end

  def citation_container_title
    "XRONOS: An Open Data Infrastructure for Archaeological Chronology"
  end

  def citation_url
    polymorphic_url(self)
  end

  def citation_accessed
    { "date-parts" => [[citation_access_date.year, citation_access_date.month, citation_access_date.day]] }
  end

  def citation_access_date
    Time.current
  end
end
