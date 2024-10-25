require 'rails_helper'

RSpec.describe "Calibration", type: :request do
  describe "GET show page" do
    it 'shows calibration for regular date' do
      @c14 = FactoryBot.create(:c14)
      visit c14_path(@c14)
      #sleep(inspection_time=5)
      expect(page).to have_selector('div', class: 'vega-embed')
    end
    
    it 'does not show calibration for date with bp to low' do
      @c14 = FactoryBot.create(:c14, bp: 170, std: 170)
      visit c14_path(@c14)
      expect(page).to have_content('can not be calculated')
    end
    
    it 'shows calibration for date with bp to high' do
      @c14 = FactoryBot.create(:c14, bp: 100000, std: 1000)
      visit c14_path(@c14)
      sleep(inspection_time=5)
      expect(page).to have_selector('div', class: 'vega-embed')
    end
  end
end
