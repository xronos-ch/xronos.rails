require "test_helper"

class C14::CitationControllerTest < ActionDispatch::IntegrationTest
  setup { @c14 = create(:c14, lab_identifier: "OxA-12345") }

  test "show returns BibTeX when format=bibtex" do
    get c14_citation_path(@c14, format: :bibtex)
    assert_response :success
    assert_equal "application/x-bibtex", response.media_type
    assert_match(/^@dataset\{xronos_c14_#{@c14.id},/, response.body)
    assert_includes response.body, "OxA-12345 (radiocarbon date)"
  end

  test "show returns CSL-JSON when format=json" do
    get c14_citation_path(@c14, format: :json)
    assert_response :success
    assert_equal "application/json", response.media_type
    body = JSON.parse(response.body)
    assert_equal "entry", body["type"]
    assert_equal "OxA-12345 (radiocarbon date)", body["title"]
  end

  test "show returns YAML when format=yaml" do
    get c14_citation_path(@c14, format: :yaml)
    assert_response :success
    assert_equal "text/yaml", response.media_type
    body = YAML.safe_load(response.body, permitted_classes: [Symbol])
    assert_equal "entry", body["type"]
  end

  test "show returns RIS when format=ris" do
    get c14_citation_path(@c14, format: :ris)
    assert_response :success
    assert_equal "application/x-research-info-systems", response.media_type
    assert_match(/^TY  - DATA/, response.body)
    assert_includes response.body, "TI  - OxA-12345 (radiocarbon date)"
    assert_includes response.body, "UR  - http://localhost:3000/c14s/#{@c14.id}"
    assert_match(/^ER  - /, response.body)
  end

  test "show without format redirects to the c14 show with anchor" do
    get c14_citation_path(@c14)
    assert_redirected_to c14_path(@c14, anchor: "c14-citation")
  end

  test "show is publicly accessible without sign-in" do
    get c14_citation_path(@c14, format: :bibtex)
    assert_response :success
  end

  test "download filenames are derived from the record" do
    get c14_citation_path(@c14, format: :bibtex)
    assert_match(/attachment; filename="c14_#{@c14.id}\.bib"/,
      response.headers["Content-Disposition"])
  end
end
