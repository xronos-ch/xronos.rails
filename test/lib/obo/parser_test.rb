require 'test_helper'

class Obo::ParserTest < ActiveSupport::TestCase
  setup do
    @sample = Tempfile.new(['sample', '.obo'])
    Obo::SpecHelper.write_sample(@sample.path)
    @sample.close
  end

  teardown do
    @sample&.unlink
  end

  test 'yields a hash for every [Term] stanza' do
    terms = Obo::Parser.each_term(@sample.path).to_a
    ids = terms.map { |t| t[:id] }

    assert_equal %w[TEST:0000001 TEST:0000002 TEST:0000003 TEST:0000004 TEST:0000005], ids
  end

  test 'skips [Typedef] and other non-Term stanzas' do
    fixture_lines = File.read(@sample.path)
    assert_includes fixture_lines, '[Typedef]'

    terms = Obo::Parser.each_term(@sample.path).to_a
    assert(terms.none? { |t| t[:id] == 'part_of' })
  end

  test 'skips the file header (key/value lines before the first [Stanza])' do
    terms = Obo::Parser.each_term(@sample.path).to_a
    assert(terms.none? { |t| t[:id] == 'format-version' })
    assert(terms.none? { |t| t[:id] == 'saved-by' })
  end

  test 'extracts id and name verbatim' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    assert_equal 'alpha', alpha[:name]
  end

  test 'extracts namespace when present' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    assert_equal 'anatomy', alpha[:namespace]
  end

  test 'leaves namespace nil when absent' do
    delta = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000004' }
    assert_nil delta[:namespace]
  end

  test 'extracts and HTML-decodes definition text, dropping the [dbxref-list]' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    assert_equal 'The first letter of the Greek alphabet.', alpha[:definition]
  end

  test 'extracts and HTML-decodes definitions with numeric character references' do
    gamma = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000003' }
    assert_includes gamma[:definition], 'γ'
  end

  test 'drops trailing {modifiers} from definition' do
    delta = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000004' }
    assert_equal 'Trailing-modifier test.', delta[:definition]
  end

  test 'extracts subsets as an array' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    assert_equal ['reference'], alpha[:subsets]
  end

  test 'extracts alt_ids as an array' do
    beta = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000002' }
    assert_equal ['TEST:0000003', 'TEST:0000004'], beta[:alt_ids]
  end

  test 'marks is_obsolete when the flag is set' do
    delta = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000004' }
    assert_equal true, delta[:is_obsolete]
  end

  test 'leaves is_obsolete false when the flag is absent' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    assert_equal false, alpha[:is_obsolete]
  end

  test 'parses EXACT and RELATED synonyms' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    types = alpha[:synonyms].map { |s| s[:type] }

    assert_includes types, 'EXACT'
    assert_includes types, 'RELATED'
  end

  test 'HTML-decodes synonym text including numeric character references' do
    epsilon = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000005' }
    first = epsilon[:synonyms].first

    assert_equal 'εpsilon (Spanish, exact)', first[:text]
  end

  test 'captures the language tag on a synonym when present' do
    epsilon = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000005' }
    first = epsilon[:synonyms].first

    assert_equal 'Spanish', first[:language]
  end

  test 'leaves language nil on a synonym when absent' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    exact = alpha[:synonyms].find { |s| s[:type] == 'EXACT' && s[:text] == 'alpha (exact)' }

    assert_nil exact[:language]
  end

  test 'ignores synonym-type IDs (e.g., OMO:0003004) when picking language' do
    gamma = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000003' }
    narrow = gamma[:synonyms].first

    assert_equal 'NARROW', narrow[:type]
    assert_nil narrow[:language]
  end

  test 'ignores the dbxref-list at the end of a synonym line' do
    alpha = Obo::Parser.each_term(@sample.path).find { |t| t[:id] == 'TEST:0000001' }
    related = alpha[:synonyms].find { |s| s[:type] == 'RELATED' }

    assert_equal 'alfa', related[:text]
  end

  test 'yields terms from an enumerator when no block is given' do
    enum = Obo::Parser.each_term(@sample.path)
    assert_respond_to enum, :each
    assert_equal 5, enum.to_a.size
  end

  test 'yields the final stanza when the file does not end with a blank line' do
    Tempfile.create(['no-trailing-blank', '.obo']) do |f|
      f.write <<~OBO
        format-version: 1.2
        [Term]
        id: NOBLANK:0000001
        name: trailing
      OBO
      f.close

      terms = Obo::Parser.each_term(f.path).to_a
      assert_equal 1, terms.size
      assert_equal 'NOBLANK:0000001', terms.first[:id]
    end
  end

  # --- variant_values_for ---

  def synonym(text, type, language: nil)
    { text: text, type: type, language: language }
  end

  test 'variant_values_for returns EXACT and RELATED synonyms plus alt_ids' do
    values = Obo::Parser.variant_values_for(
      { synonyms: [
          synonym('a', 'EXACT'),
          synonym('b', 'RELATED'),
          synonym('c', 'NARROW'),
          synonym('d', 'BROAD')
        ],
        alt_ids: ['ALT:1', 'ALT:2'] }
    )

    assert_equal %w[a b ALT:1 ALT:2], values
  end

  test 'variant_values_for drops empty or blank values' do
    values = Obo::Parser.variant_values_for(
      { synonyms: [synonym('', 'EXACT'), synonym(' ', 'RELATED'), synonym('real', 'EXACT')],
        alt_ids: [''] }
    )

    assert_equal %w[real], values
  end

  test 'variant_values_for dedupes case-insensitively' do
    values = Obo::Parser.variant_values_for(
      { synonyms: [synonym('Cob', 'EXACT'), synonym('cob', 'RELATED'), synonym('COB', 'EXACT')],
        alt_ids: [] }
    )

    assert_equal %w[Cob], values
  end

  test "variant_values_for preserves the first occurrence's text on dedup" do
    values = Obo::Parser.variant_values_for(
      { synonyms: [synonym('maize cob', 'EXACT'), synonym('MAIZE COB', 'RELATED')],
        alt_ids: [] }
    )

    assert_equal 'maize cob', values.first
  end
end
