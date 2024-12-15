require 'rails_helper'

RSpec.describe "dendros/show", type: :view do
  before(:each) do
    @dendro = assign(:dendro, Dendro.create!(
      sample: nil,
      series_code: "Series Code",
      name: "Name",
      description: "MyText",
      start_year: 2,
      end_year: 3,
      is_anchored: false,
      offset: 4,
      measurements: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Series Code/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(//)
  end
end
