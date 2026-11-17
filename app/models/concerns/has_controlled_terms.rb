module HasControlledTerms
  extend ActiveSupport::Concern

  class_methods do
    def controlled_term(attribute, vocabulary:)
      attribute = attribute.to_sym
      controlled_terms[attribute] = vocabulary.to_s

      define_method("#{attribute}_controlled?") { controlled?(attribute) }
      define_method("#{attribute}_vocabulary")  { vocabulary_for(attribute) }
      define_method("#{attribute}_term")       { term_for(attribute) }
      define_method("#{attribute}_terms")      { terms_for(attribute) }
      define_method("#{attribute}_ontologies") { ontologies_for(attribute) }

      scope "controlled_#{attribute}",   -> { controlled(attribute) }
      scope "uncontrolled_#{attribute}", -> { uncontrolled(attribute) }
    end

    def controlled_terms
      @controlled_terms ||= {}
    end

    def controlled(attribute)
      attribute = attribute.to_sym
      name = controlled_terms[attribute]
      raise ArgumentError, "No controlled_term declared for #{name}##{attribute}" unless name

      vocab_name = connection.quote(name)
      col        = connection.quote_column_name(attribute)
      table      = connection.quote_table_name(table_name)

      where("""
        EXISTS (
          SELECT 1 FROM controlled_vocabulary_terms t
          INNER JOIN controlled_vocabularies c ON c.id = t.controlled_vocabulary_id
          WHERE c.name = #{vocab_name}
            AND t.name = #{table}.#{col}
        )
      """)
    end

    def uncontrolled(attribute)
      attribute = attribute.to_sym
      name = controlled_terms[attribute]
      raise ArgumentError, "No controlled_term declared for #{name}##{attribute}" unless name

      vocab_name = connection.quote(name)
      col        = connection.quote_column_name(attribute)
      table      = connection.quote_table_name(table_name)

      where("""
        NOT EXISTS (
          SELECT 1 FROM controlled_vocabulary_terms t
          INNER JOIN controlled_vocabularies c ON c.id = t.controlled_vocabulary_id
          WHERE c.name = #{vocab_name}
            AND t.name = #{table}.#{col}
        )
      """)
    end
  end

  def controlled?(attribute)
    term_for(attribute).present?
  end

  def vocabulary_for(attribute)
    name = self.class.controlled_terms[attribute.to_sym]
    return nil if name.blank?
    ControlledVocabulary.find_by(name: name)
  end

  def term_for(attribute)
    vocab = vocabulary_for(attribute)
    return nil if vocab.nil?
    value = public_send(attribute)
    return nil if value.blank?
    vocab.match(value)
  end

  # Plural form of #term_for. Returns every term in the declared
  # vocabulary whose name equals the attribute value. The value may
  # match multiple terms across ontologies (e.g. PO and UBERON both have
  # a "cortex"); all matches are returned so the consumer can surface
  # the ambiguity. The order matches ControlledVocabulary#matches.
  def terms_for(attribute)
    vocab = vocabulary_for(attribute)
    return [] if vocab.nil?
    value = public_send(attribute)
    return [] if value.blank?
    vocab.matches(value).to_a
  end

  def ontologies_for(attribute)
    terms_for(attribute)
      .reject { |t| t.ontology_name.blank? }
      .map { |t| { name: t.ontology_name, id: t.ontology_id, url: t.ontology_url }.compact }
  end

  # Resolve a user-typed string to the canonical term for the declared
  # vocabulary's variant thesaurus. Returns the term or nil.
  def resolve_variant_for(attribute, input)
    vocab = vocabulary_for(attribute)
    return nil if vocab.nil?
    vocab.resolve_variant(input)
  end
end
