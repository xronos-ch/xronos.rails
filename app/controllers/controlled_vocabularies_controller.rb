class ControlledVocabulariesController < ApplicationController
  authorize_resource class: "ControlledVocabulary"

  MAX_RESULTS = 20

  Result = Struct.new(:term, :match, :matched_variant, :tier, keyword_init: true) do
    delegate :name, :ontology_name, :ontology_id, :ontology_url, :description_excerpt,
      to: :term
  end

  # GET /controlled_vocabularies.json?vocabulary=part_of_organism&q=maize
  def index
    return head :bad_request if params[:vocabulary].blank? || params[:vocabulary].is_a?(Array)

    @vocabulary = ControlledVocabulary.find_by(name: params[:vocabulary])
    return head :not_found unless @vocabulary

    @results = build_index_results

    respond_to(&:json)
  end

  private

  # Build results in five priority tiers (lower tier number = higher
  # priority). Each tier skips terms already present in higher tiers:
  #
  #   1. Exact term-name match (case-insensitive)
  #   2. Exact variant match (via #resolve_variant, case-insensitive)
  #   3. Prefix term-name match (case-insensitive)
  #   4. Variant word-boundary prefix match
  #   5. All other matches (substring via pg_search tsearch)
  #
  # Within a tier, pg_search's tsearch rank breaks ties. The combined
  # list is capped at MAX_RESULTS.
  def build_index_results
    return default_results if params[:q].blank?

    query = params[:q]
    results = []
    seen_ids = Set.new

    [
      -> { exact_name_matches(query, seen_ids) },
      -> { exact_variant_matches(query, seen_ids) },
      -> { prefix_name_matches(query, seen_ids) },
      -> { variant_word_matches(query, seen_ids) },
      -> { other_matches(query, seen_ids) }
    ].each do |tier|
      break if results.length >= MAX_RESULTS
      tier.call.each do |result|
        next if seen_ids.include?(result.term.id)
        seen_ids << result.term.id
        results << result
        break if results.length >= MAX_RESULTS
      end
    end

    results
  end

  def default_results
    @vocabulary.terms.limit(MAX_RESULTS).map do |t|
      Result.new(term: t, match: "term", tier: 5)
    end
  end

  # Tier 1: exact term-name match (case-insensitive).
  def exact_name_matches(query, _seen_ids)
    @vocabulary.terms
               .where("LOWER(name) = ?", query.downcase)
               .map { |t| Result.new(term: t, match: "term", tier: 1) }
  end

  # Tier 2: exact variant match (case-insensitive via normalization).
  # We do a direct variant lookup (rather than #resolve_variant) so the
  # response can include the stored +value+ rather than the user's input.
  def exact_variant_matches(query, _seen_ids)
    needle = ControlledVocabulary::Variant.normalize_for_matching(query)
    return [] if needle.empty?
    variant = ControlledVocabulary::Variant
                            .joins(:term)
                            .where(controlled_vocabulary_terms: { controlled_vocabulary_id: @vocabulary.id })
                            .find_by(normalized: needle)
    return [] unless variant
    [Result.new(term: variant.term, match: "variant",
                matched_variant: variant.value, tier: 2)]
  end

  # Tier 3: prefix term-name match (case-insensitive).
  def prefix_name_matches(query, _seen_ids)
    @vocabulary.terms
               .where("LOWER(name) LIKE ?", "#{query.downcase}%")
               .map { |t| Result.new(term: t, match: "term", tier: 3) }
  end

  # Tier 4: variant word-boundary prefix. A variant matches when any
  # whitespace-separated word in its value starts with the query.
  def variant_word_matches(query, _seen_ids)
    @vocabulary.search_variants(query).filter_map do |variant|
      next unless variant_word_boundary?(variant.value, query)
      Result.new(term: variant.term, match: "variant",
                 matched_variant: variant.value, tier: 4)
    end
  end

  # Tier 5: everything else. Variant matches via tsearch (substring
  # anywhere in the value) and term-name matches via tsearch (substring
  # anywhere in the name), minus any term ids already claimed by higher
  # tiers.
  def other_matches(query, seen_ids)
    results = []

    @vocabulary.search_variants(query).each do |variant|
      next if seen_ids.include?(variant.controlled_vocabulary_term_id)
      seen_ids << variant.controlled_vocabulary_term_id
      results << Result.new(term: variant.term, match: "variant",
                            matched_variant: variant.value, tier: 5)
    end

    @vocabulary.terms
               .search(query)
               .where.not(id: seen_ids.to_a)
               .each do |t|
      results << Result.new(term: t, match: "term", tier: 5)
    end

    results
  end

  # Tokenize both the query and the variant value, then require each
  # query token to be a prefix of some word in the value. Case-insensitive.
  # Used to distinguish a "tuber" → "tuberous root" word-boundary match
  # from a "tuber" → "islands of Calleja (olfactory tubercle)" match
  # (the latter still qualifies, since "tubercle)" starts with "tuber"),
  # while rejecting pure substring matches like "uber" within "puberty".
  # Multi-word queries like "maize c" match "maize cob" because each
  # query token ("maize", "c") prefixes a word in the value.
  def variant_word_boundary?(value, query)
    return false if value.blank? || query.blank?
    value_words = value.downcase.split(/\s+/)
    query.downcase.split(/\s+/).all? do |token|
      value_words.any? { |word| word.start_with?(token) }
    end
  end
end
