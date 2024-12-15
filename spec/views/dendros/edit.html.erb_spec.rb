require 'rails_helper'

RSpec.describe "dendros/edit", type: :view do
  before(:each) do
    @dendro = assign(:dendro, Dendro.create!(
      sample: nil,
      series_code: "MyString",
      name: "MyString",
      description: "MyText",
      start_year: 1,
      end_year: 1,
      is_anchored: false,
      offset: 1,
      measurements: ""
    ))
  end

  it "renders the edit dendro form" do
    render

    assert_select "form[action=?][method=?]", dendro_path(@dendro), "post" do

      assert_select "input[name=?]", "dendro[sample_id]"

      assert_select "input[name=?]", "dendro[series_code]"

      assert_select "input[name=?]", "dendro[name]"

      assert_select "textarea[name=?]", "dendro[description]"

      assert_select "input[name=?]", "dendro[start_year]"

      assert_select "input[name=?]", "dendro[end_year]"

      assert_select "input[name=?]", "dendro[is_anchored]"

      assert_select "input[name=?]", "dendro[offset]"

      assert_select "input[name=?]", "dendro[measurements]"
    end
  end
end
