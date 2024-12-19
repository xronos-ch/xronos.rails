require 'rails_helper'

RSpec.describe "dendros/index", type: :view do
  before(:each) do
    @sample1 = create(:sample)
    @sample2 = create(:sample)
    assign(:pagy, Pagy.new(count: 2, page: 1))
    @dendro1 = create(:dendro, sample: @sample1)
    @dendro2 = create(:dendro, sample: @sample2)
    assign(:dendros, [@dendro1, @dendro2])
  end

  it "renders a list of dendros" do
    render
    assert_select "tr>td", text: @dendro1.site.name, count: 1
    assert_select "tr>td", text: @dendro2.site.name, count: 1
    assert_select "tr>td", text: @dendro1.name, count: 1
    assert_select "tr>td", text: @dendro2.name, count: 1
    assert_select "tr>td", text: @dendro1.start_year.to_s, count: 1
    assert_select "tr>td", text: @dendro1.end_year.to_s, count: 1
    assert_select "tr>td", text: @dendro2.start_year.to_s, count: 1
    assert_select "tr>td", text: @dendro2.end_year.to_s, count: 1
  end
end