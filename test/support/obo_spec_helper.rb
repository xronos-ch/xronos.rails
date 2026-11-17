module Obo
  # Shared OBO test data for the parser test suite. The sample OBO is
  # small but exercises every parser path: header lines, [Term] and
  # [Typedef] stanzas, definitions with refs and {modifiers}, EXACT and
  # RELATED synonyms, language tags, alt_ids, is_obsolete, and HTML
  # numeric character references.
  module SpecHelper
    module_function

    def sample_obo_content
      <<~OBO
        format-version: 1.2
        data-version: test/2026-01-01/sample
        saved-by: xronos-test
        default-namespace: sample_ontology
        synonymtypedef: Spanish "Spanish synonym (exact)" EXACT

        [Term]
        id: TEST:0000001
        name: alpha
        namespace: anatomy
        def: "The first letter of the Greek alphabet." [Wikipedia:Greek_alphabet]
        synonym: "alpha (exact)" EXACT []
        synonym: "alfa" RELATED [WIKIDATA:Q3]
        synonym: "alfa (Spanish, exact)" EXACT Spanish [WIKIDATA:Q3]
        subset: reference
        is_a: TEST:0000099 ! root

        [Term]
        id: TEST:0000002
        name: beta
        namespace: anatomy
        def: "The second letter." [Wikipedia:Greek_alphabet]
        alt_id: TEST:0000003
        alt_id: TEST:0000004
        synonym: "beta (exact)" EXACT []
        synonym: "Greek beta (narrow)" NARROW []
        subset: reference
        is_a: TEST:0000001 ! alpha

        [Term]
        id: TEST:0000003
        name: gamma
        namespace: anatomy
        def: "Letter with HTML entity: &#947;." [TEST:curator]
        synonym: "gamma (narrow, plural)" NARROW OMO:0003004 []
        is_a: TEST:0000002 ! beta

        [Term]
        id: TEST:0000004
        name: delta
        def: "Trailing-modifier test." [TEST:curator] {source="TEST"}
        synonym: "delta (broad)" BROAD []
        is_obsolete: true

        [Typedef]
        id: part_of
        name: part of

        [Term]
        id: TEST:0000005
        name: epsilon
        namespace: anatomy
        synonym: "&#949;psilon (Spanish, exact)" EXACT Spanish []
        subset: reference
      OBO
    end

    def write_sample(path)
      File.write(path, sample_obo_content)
    end
  end
end
