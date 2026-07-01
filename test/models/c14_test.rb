# == Schema Information
#
# Table name: c14s
# Database name: primary
#
#  id             :bigint           not null, primary key
#  bp             :integer
#  cal_bp         :integer
#  cal_std        :integer
#  delta_15n      :float
#  delta_c13      :float
#  delta_c13_std  :float
#  lab_identifier :string
#  method         :string
#  std            :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  c14_lab_id     :bigint
#  sample_id      :bigint
#
# Indexes
#
#  index_c14s_on_c14_lab_id      (c14_lab_id)
#  index_c14s_on_lab_identifier  (lab_identifier)
#  index_c14s_on_method          (sample_id)
#
require "test_helper"

class C14Test < ActiveSupport::TestCase

  test "destroying a c14 destroys its citations" do
    c14 = create(:c14, :with_citations, citations_count: 2)
    assert_dependent_destroy(c14, :citations, count: 2)
  end

  test "citation title is the lab_identifier" do
    c14 = create(:c14, lab_identifier: "OxA-12345")
    assert_equal "OxA-12345 (radiocarbon date)", c14.citation['title']
  end

  test "citation title falls back to a generic label when lab_identifier is missing" do
    c14 = create(:c14, lab_identifier: nil)
    assert_equal "C14 record ##{c14.id} (radiocarbon date)", c14.citation['title']
  end

  test "citation title is the lab_identifier even when it does not parse" do
    c14 = create(:c14, lab_identifier: "not a real lab id")
    assert_equal "not a real lab id (radiocarbon date)", c14.citation['title']
  end

  test "citation id is prefixed with xronos_c14_" do
    c14 = create(:c14)
    assert_equal "xronos_c14_#{c14.id}", c14.citation['id']
  end

  test "citation URL is the c14 permalink" do
    c14 = create(:c14)
    assert_equal "http://localhost:3000/c14s/#{c14.id}", c14.citation['URL']
  end

  test "render_citation returns an html-safe string containing the URL" do
    c14 = create(:c14, lab_identifier: "OxA-12345")
    rendered = c14.render_citation
    assert_predicate rendered, :html_safe?
    assert_includes rendered, "http://localhost:3000/c14s/#{c14.id}"
  end

  test "format_bibtex returns a BibTeX entry string" do
    c14 = create(:c14, lab_identifier: "OxA-12345")
    bib = c14.format_bibtex
    assert_match(/^@dataset\{xronos_c14_#{c14.id},/, bib)
    assert_includes bib, "OxA-12345 (radiocarbon date)"
  end

  test "format_bibtex double-braces the XRONOS Core Team admin author" do
    admin = create(:user)
    admin.user_profile.update!(full_name: "Zara Admin")
    with_env("ADMIN_USER_ID" => admin.id.to_s) do
      c14 = create(:c14, lab_identifier: "OxA-12345")
      bib = c14.format_bibtex
      assert_includes bib, "{{XRONOS Core Team}}"
    end
  end

  private

  def with_env(vars)
    previous = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    previous.each { |k, v| ENV[k] = v }
  end

  test "format_json returns CSL-JSON" do
    c14 = create(:c14, lab_identifier: "OxA-12345")
    json = JSON.parse(c14.format_json)
    assert_equal "entry", json["type"]
    assert_equal "xronos_c14_#{c14.id}", json["id"]
    assert_equal "OxA-12345 (radiocarbon date)", json["title"]
  end

  test "format_yaml returns YAML serialization" do
    c14 = create(:c14, lab_identifier: "OxA-12345")
    yaml = YAML.safe_load(c14.format_yaml, permitted_classes: [Symbol])
    assert_equal "entry", yaml["type"]
  end

  test "format_ris returns a RIS record" do
    c14 = create(:c14, lab_identifier: "OxA-12345")
    ris = c14.format_ris
    assert_match(/^TY  - DATA/, ris)
    assert_includes ris, "TI  - OxA-12345 (radiocarbon date)"
    assert_includes ris, "UR  - http://localhost:3000/c14s/#{c14.id}"
    assert_match(/^ER  - /, ris)
  end

end
