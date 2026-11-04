require "test_helper"

class ReferencesHelperTest < ActionView::TestCase
  test "csl_display_fields orders preferred fields first, then the rest alphabetically, without internal keys" do
    item = {
      "page" => "1-10",
      "title" => "A title",
      "abstract" => "An abstract",
      "type" => "article-journal",
      "id" => "internal",
      "_raw_bibtex" => "junk"
    }

    assert_equal %w[type title page abstract], csl_display_fields(item)
  end

  test "csl_field_label humanises keys and keeps acronyms" do
    assert_equal "Container title", csl_field_label("container-title")
    assert_equal "Issued", csl_field_label("issued")
    assert_equal "DOI", csl_field_label("DOI")
    assert_equal "URL", csl_field_label("URL")
  end

  test "csl_field_value formats name arrays" do
    value = [
      { "family" => "Doe", "given" => "Jane" },
      { "family" => "Roe", "given" => "Jo" },
      { "literal" => "Research Team X" }
    ]

    assert_equal "Doe, Jane; Roe, Jo; Research Team X", csl_field_value("author", value)
  end

  test "csl_field_value escapes HTML in names" do
    assert_equal "&lt;b&gt;", csl_field_value("author", [ { "literal" => "<b>" } ])
  end

  test "csl_field_value formats date-parts" do
    assert_equal "2020", csl_field_value("issued", { "date-parts" => [ [ 2020 ] ] })
    assert_equal "2020-05-01", csl_field_value("issued", { "date-parts" => [ [ 2020, 5, 1 ] ] })
  end

  test "csl_field_value uses the literal for dates without date-parts" do
    assert_equal "n.d.", csl_field_value("issued", { "literal" => "n.d." })
  end

  test "csl_field_value links DOIs and URLs" do
    assert_equal '<a href="https://doi.org/10.1234/x">10.1234/x</a>', csl_field_value("DOI", "10.1234/x")
    assert_equal '<a href="https://example.com">https://example.com</a>',
      csl_field_value("URL", "https://example.com")
  end

  test "csl_field_value stringifies other scalars" do
    assert_equal "62", csl_field_value("volume", 62)
    assert_equal "article-journal", csl_field_value("type", "article-journal")
  end
end
