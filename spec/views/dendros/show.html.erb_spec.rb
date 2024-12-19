require 'rails_helper'

RSpec.describe "dendros/show", type: :view do
  before(:each) do
    @sample = create(:sample) # Create a valid sample using FactoryBot
    @dendro = assign(:dendro, Dendro.create!(
      sample: @sample,
      series_code: "Series Code",
      name: "Name",
      description: "MyText",
      start_year: 2,
      end_year: 3,
      is_anchored: false,
      offset: 4,
      measurements: [{ year: 1, value: 0.5 }] # Provide valid measurements
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Series Code/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
  end
end