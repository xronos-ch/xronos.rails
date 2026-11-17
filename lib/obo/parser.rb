require 'cgi'
require 'set'

module Obo
  # Streaming parser for OBO 1.2 format files.
  #
  # Yields one parsed-term hash per [Term] stanza, skipping the file
  # header, [Typedef], [Instance], and any other non-Term stanzas. The
  # parser is generic: it does not apply source-specific filters (those
  # belong to the rake task) and it has no DB knowledge.
  #
  # Each yielded hash has:
  #   id           - String, e.g. "UBERON:0000002" or "PO:0000003"
  #   name         - String
  #   namespace    - String or nil (only present in PO)
  #   definition   - String or nil, HTML-entity-decoded
  #   synonyms     - Array<Hash{text:, type:, language:}>, HTML-decoded;
  #                  type is one of EXACT, RELATED, NARROW, BROAD;
  #                  language is the optional language tag, nil if absent
  #   alt_ids      - Array<String>
  #   subsets      - Array<String>
  #   is_obsolete  - Boolean (false when absent)
  #
  # String values in the source are HTML-entity-decoded via CGI.unescapeHTML
  # (covers &amp; &lt; &gt; &quot; &apos; and &#NNN; numeric refs).
  # The OBO escape sequences \n, \", \\ are not decoded: they have not
  # been observed in the UBERON or PO files we ingest, and the OBO 1.2
  # grammar only requires that they appear inside quoted strings, which
  # we do not currently need to surface.
  module Parser
    SYNONYM_TYPES = %w[EXACT RELATED NARROW BROAD].freeze

    def self.each_term(path, &block)
      return enum_for(:each_term, path) unless block_given?

      in_term = false
      fields = nil

      File.foreach(path) do |line|
        line = line.chomp
        stripped = line.strip

        if stripped.empty?
          yield_term(fields, &block) if in_term
          in_term = false
          fields = nil
          next
        end

        if stripped.start_with?('[')
          in_term = (stripped == '[Term]')
          fields = in_term ? {} : nil
          next
        end

        next unless in_term

        key, _, value = line.partition(':')
        next if value.empty?

        consume(fields, key.strip, value.strip)
      end

      yield_term(fields, &block) if in_term
    end

    def self.consume(fields, key, value)
      case key
      when 'id'          then fields[:id] = CGI.unescapeHTML(value)
      when 'name'        then fields[:name] = CGI.unescapeHTML(value)
      when 'namespace'   then fields[:namespace] = CGI.unescapeHTML(value)
      when 'def'         then fields[:definition] = parse_def(value)
      when 'is_obsolete' then fields[:is_obsolete] = (value == 'true')
      when 'subset'
        (fields[:subsets] ||= []) << value
      when 'alt_id'
        (fields[:alt_ids] ||= []) << CGI.unescapeHTML(value)
      when 'synonym'
        parsed = parse_synonym(value)
        (fields[:synonyms] ||= []) << parsed if parsed
      end
    end

    # Extract the definition text from a `def:` value, dropping the
    # trailing [dbxref-list] and optional {modifiers}.
    def self.parse_def(value)
      text = value.sub(/\s*\[[^\]]*\]\s*(?:\{[^}]*\})?\s*$/, '').strip
      text = text.sub(/\s*\{[^}]*\}\s*$/, '').strip if text == value
      CGI.unescapeHTML(text.tr('"', ''))
    end

    # Parse a `synonym:` value of the form
    #   "text" TYPE [dbxref-list]
    #   "text" TYPE OMO:NNNNN [dbxref-list]
    #   "text" TYPE LANGUAGE [dbxref-list]
    #   "text" TYPE LANGUAGE OMO:NNNNN [dbxref-list]
    # Returns nil for unparseable input.
    def self.parse_synonym(value)
      cleaned = value.sub(/\s*\[[^\]]*\]\s*$/, '').rstrip
      match = cleaned.match(/\A"((?:[^"\\]|\\.)*)"\s+(\S+)(.*)\z/m)
      return nil unless match

      text = match[1]
      second = match[2]
      rest = match[3].to_s.strip
      return nil unless SYNONYM_TYPES.include?(second)

      language = nil
      rest.split(/\s+/).each do |token|
        next if token.empty?
        next if token == second
        next if token.match?(/\A[A-Za-z][A-Za-z0-9_]*:\d+\z/)

        language = token
      end

      { text: CGI.unescapeHTML(text), type: second, language: language }
    end

    def self.yield_term(fields)
      return unless fields && fields[:id] && fields[:name]

      yield({
        id: fields[:id],
        name: fields[:name],
        namespace: fields[:namespace],
        definition: fields[:definition],
        synonyms: fields[:synonyms] || [],
        alt_ids: fields[:alt_ids] || [],
        subsets: fields[:subsets] || [],
        is_obsolete: fields[:is_obsolete] || false
      })
    end

    # Extract the deduped variant values for a parsed OBO term:
    # - synonyms of the allowed types (default EXACT, RELATED), any language
    # - alt_id values
    # Deduplication is case-insensitive, going through
    # ControlledVocabulary::Variant.normalize_for_matching so that two source
    # values which would resolve to the same Variant row are kept once.
    # Depends on the model's normalize function (the only coupling between
    # this pure parser and ActiveRecord); if the parser grows another
    # variant-derivation use case, consider extracting StringNormalize.
    def self.variant_values_for(term, allowed_types: %w[EXACT RELATED])
      seen = Set.new
      result = []

      (term[:synonyms]
         .select { |s| allowed_types.include?(s[:type]) && s[:text].present? }
         .map    { |s| s[:text] } +
       term[:alt_ids].select(&:present?)).each do |value|
        normalized = ControlledVocabulary::Variant.normalize_for_matching(value)
        next if normalized.empty?
        next if seen.include?(normalized)

        seen.add(normalized)
        result << value
      end

      result
    end
  end
end
