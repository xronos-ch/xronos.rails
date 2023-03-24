require 'rails_helper'

RSpec.describe "User Interactions", type: :request, js: true do
  describe "signing in" do

    before(:each) do
      @user = User.create!(:email => 'test@example.com', :password => 'f4k3p455w0rd')
      @user_profile = UserProfile.create!(first_name: "Horst", last_name: "Hans", user: @user)
      @admin_user = FactoryBot.create(:user, :admin)
      @admin_user_profile = UserProfile.create!(first_name: "Willi", last_name: "Wichtig", user: @admin_user)
     end
     
    it "has a Sign in Button" do
      visit root_path
      expect(page).to have_button('Sign in')
    end
    
    it "allows users to sign in" do
      visit root_path
      click_button('Sign in')
      fill_in 'user_email', :with => @user.email
      fill_in 'user_password', :with => @user.password
      find('input[name="commit"]').click
      expect(page).to have_button(@user.email)
    end
    
    it "allows authenticated access" do
      sign_in @user
      visit 'user_profile'
      expect(page).to have_content(@user.email)
    end
  end

  describe "capabilities" do
    
    before(:each) do
      @user = User.create!(:email => 'test@example.com', :password => 'f4k3p455w0rd')
      @user_profile = UserProfile.create!(first_name: "Horst", last_name: "Hans", user: @user)
      @admin_user = FactoryBot.create(:user, :admin)
      @admin_user_profile = UserProfile.create!(first_name: "Willi", last_name: "Wichtig", user: @admin_user)
     end
     
    it "blocks normal users from seeing the user profile index" do
      sign_in @user
      expect{
         get '/user_profiles'
       }.to raise_error(ActionController::RoutingError)
    end

    it "allows admin users to see the user profile index" do
      sign_in @admin_user
      expect{visit 'user_profiles'}.not_to raise_error
    end
    
    it "hides admin checkbox from normal users" do
      sign_in @user
      visit 'user_profile'
      click_link('Edit')
      expect(page).not_to have_field("user_profile_user_attributes_admin")
    end
    
    it "shows admin checkbox to admin users" do
      sign_in @admin_user
      visit 'user_profile'
      click_link('Edit')
      expect(page).to have_field("user_profile_user_attributes_admin")
    end
  end
end
