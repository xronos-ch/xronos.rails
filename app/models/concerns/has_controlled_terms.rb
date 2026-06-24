module HasControlledTerms
  extend ActiveSupport::Concern

  class_methods do
    def controlled_term(attribute, vocabulary:)
      attribute = attribute.to_sym
      controlled_terms[attribute] = vocabulary.to_s

      define_method("#{attribute}_controlled?") { controlled?(attribute) }
      define_method("#{attribute}_vocabulary")  { vocabulary_for(attribute) }
      define_method("#{attribute}_term")       { term_for(attribute) }
      define_method("#{attribute}_ontologies") { ontologies_for(attribute) }

      scope "controlled_#{attribute}",   -> { controlled(attribute) }
      scope "uncontrolled_#{attribute}", -> { uncontrolled(attribute) }
    end

    def controlled_terms
      @controlled_terms ||= {}
    end

    def controlled(attribute)
      attribute = attribute.to_sym
      vocab = vocabulary_for_scope(attribute)
      return none if vocab.nil?

      needles = vocabulary_needles(vocab)
      return none if needles.empty?

      col = connection.quote_column_name(attribute)
      where("LOWER(#{col}) IN (?)", needles)
    end

    def uncontrolled(attribute)
      attribute = attribute.to_sym
      vocab = vocabulary_for_scope(attribute)
      return all if vocab.nil?

      needles = vocabulary_needles(vocab)
      return all if needles.empty?

      col = connection.quote_column_name(attribute)
      where.not("LOWER(#{col}) IN (?)", needles)
    end

    private

    def vocabulary_for_scope(attribute)
      name = controlled_terms[attribute]
      raise ArgumentError, "No controlled_term declared for #{name}##{attribute}" unless name
      ControlledVocabulary.find_by(name: name)
    end

    def vocabulary_needles(vocab)
      term_names = vocab.terms.pluck(Arel.sql("LOWER(name)"))
      variants   = vocab.terms.joins(:variants).pluck(:normalized)
      (term_names + variants).uniq
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

  def ontologies_for(attribute)
    term = term_for(attribute)
    return [] if term.nil? || term.ontology_name.blank?
    [{ name: term.ontology_name, id: term.ontology_id, url: term.ontology_url }.compact]
  end
end
