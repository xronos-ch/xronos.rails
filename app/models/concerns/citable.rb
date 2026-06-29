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

  # CSL-JSON — canonical machine-readable form
  def format_json
    citation.to_json
  end

  # YAML serialization of the same data
  def format_yaml
    citation.to_yaml
  end

  # BibTeX entry built from the CSL hash
  def format_bibtex
    bib = BibTeX::Entry.new
    bib.type      = :dataset
    bib.key       = citation["id"]
    bib.title     = citation["title"]
    bib.year      = citation.dig("issued", "date-parts", 0, 0)
    bib.publisher = citation["container-title"]
    bib.url       = citation["URL"]
    bib.author    = Array(citation["author"]).map { |a|
      if a["literal"]
        # Double braces protect the literal name from name parsing
        # in BibTeX styles, in addition to the standard single-brace
        # name-part protection.
        "{#{a["literal"]}}"
      else
        [a["given"], a["family"]].compact.join(" ")
      end
    }.join(" and ")
    bib.to_s
  end

  # RIS — no built-in support in bibtex-ruby/citeproc; produce manually
  def format_ris
    c = citation
    lines = ["TY  - DATA"]
    lines << "TI  - #{c['title']}" if c['title']
    Array(c['author']).each do |a|
      name = a['literal'] || [a['given'], a['family']].compact.join(' ')
      lines << "AU  - #{name}" unless name.blank?
    end
    if (y = c.dig('issued', 'date-parts', 0, 0))
      lines << "PY  - #{y}"
    end
    lines << "PB  - #{c['container-title']}" if c['container-title']
    if (parts = c.dig('accessed', 'date-parts', 0))
      lines << "Y2  - #{parts[0]}-#{format('%02d', parts[1])}-#{format('%02d', parts[2])}"
    end
    lines << "UR  - #{c['URL']}" if c['URL']
    lines << "ER  - "
    lines.join("\n") + "\n"
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  # Path to this record's citation sub-resource, optionally with a format extension.
  # Used by the Cite dropdown to generate per-format download URLs.
  def citation_path(format: nil)
    helper = "#{model_name.singular}_citation_path"
    Rails.application.routes.url_helpers.send(helper, self, format: format)
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
