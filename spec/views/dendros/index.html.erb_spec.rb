require 'rails_helper'

RSpec.describe "dendros/index", type: :view do
  before(:each) do
    assign(:dendros, [
      Dendro.create!(
        sample: nil,
        series_code: "Series Code",
        name: "Name",
        description: "MyText",
        start_year: 2,
        end_year: 3,
        is_anchored: false,
        offset: 4,
        measurements: ""
      ),
      Dendro.create!(
        sample: nil,
        series_code: "Series Code",
        name: "Name",
        description: "MyText",
        start_year: 2,
        end_year: 3,
        is_anchored: false,
        offset: 4,
        measurements: ""
      )
    ])
  end

  it "renders a list of dendros" do
    render
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: "Series Code".to_s, count: 2
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: "MyText".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: 3.to_s, count: 2
    assert_select "tr>td", text: false.to_s, count: 2
    assert_select "tr>td", text: 4.to_s, count: 2
    assert_select "tr>td", text: "".to_s, count: 2
  end
end
