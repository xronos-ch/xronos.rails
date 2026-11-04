require "test_helper"

class CitationJsTest < ActiveSupport::TestCase
  test "converts CSL to BibTeX" do
    csl_items = [
      {
        "id" => "doe2020",
        "type" => "article-journal",
        "title" => "Test Article",
        "author" => [{ "family" => "Doe", "given" => "Jane" }],
        "issued" => { "date-parts" => [[2020]] },
        "container-title" => "Test Journal"
      }
    ]

    result = CitationJs.convert(csl_items, "bibtex")

    assert_includes result, "@article"
    assert_includes result, "Doe, Jane"
    assert_includes result, "Article"
    assert_includes result, "2020"
  end

  test "converts CSL to RIS" do
    csl_items = [
      {
        "id" => "doe2020",
        "type" => "article-journal",
        "title" => "Test Article",
        "author" => [{ "family" => "Doe", "given" => "Jane" }],
        "issued" => { "date-parts" => [[2020]] },
        "DOI" => "10.1234/test"
      }
    ]

    result = CitationJs.convert(csl_items, "ris")

    assert_includes result, "TY  - JOUR"
    assert_includes result, "AU  - Doe, Jane"
    assert_includes result, "TI  - Test Article"
    assert_includes result, "DO  - 10.1234/test"
    assert_includes result, "ER  - "
  end

  test "returns empty string for blank input" do
    assert_equal "", CitationJs.convert(nil, "bibtex")
    assert_equal "", CitationJs.convert([], "bibtex")
  end

  test "logs error and returns empty string on conversion failure" do
    csl_items = [{ "id" => "test", "type" => "article-journal" }]

    assert_equal "", CitationJs.convert(csl_items, "invalid_format")
  end
end
