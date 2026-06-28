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

    return head :bad_request if usage_counts_params_invalid?

    @results = build_index_results
    @usage_counts = usage_counts_for(@results.map(&:term).map(&:name))

    respond_to(&:json)
  end

  private

  # The (model, attribute) params are optional together. They're
  # malformed — and we 400 — if:
  #   - one is present without the other, or
  #   - both are present but don't name a real ActiveRecord model
  #     with a declared controlled_term on the named column.
  def usage_counts_params_invalid?
    model = params[:model]
    attribute = params[:attribute]
    return false if model.blank? && attribute.blank?
    return true  if model.blank? || attribute.blank?
    !valid_controlled_term_target?(model, attribute)
  end

  # Safelist: the (model, attribute) pair must refer to a real
  # ActiveRecord class with a column named +attribute+ that is
  # declared as a controlled_term. This prevents the search endpoint
  # from being used to count rows in arbitrary tables/columns
  # (e.g. User.email, which would be an information disclosure).
  def valid_controlled_term_target?(model_name, attribute_name)
    return false if model_name.is_a?(Array) || attribute_name.is_a?(Array)
    model_class = controlled_term_model_class(model_name)
    return false unless model_class
    return false unless model_class.column_names.include?(attribute_name)
    return false unless model_class.respond_to?(:controlled_terms)
    model_class.controlled_terms.key?(attribute_name.to_sym)
  end

  def controlled_term_model_class(model_name)
    return nil if model_name.blank? || model_name.is_a?(Array)

    allowed_models = ApplicationRecord.descendants.index_by(&:name)
    model_class = allowed_models[model_name]
    return nil unless model_class
    return nil unless model_class.respond_to?(:controlled_terms)

    model_class
  end

  # Returns a Hash of term_name => existing-record count, or nil
  # when no count was requested (both model and attribute params
  # absent). Assumes #usage_counts_params_invalid? has already
  # returned false.
  def usage_counts_for(term_names)
    return nil if params[:model].blank? || params[:attribute].blank?

    model_class = controlled_term_model_class(params[:model])
    return nil unless model_class

    model_class.where(params[:attribute] => term_names)
               .group(params[:attribute])
               .count
  end

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
