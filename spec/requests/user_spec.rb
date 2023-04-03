require 'rails_helper'

RSpec.describe "User Interactions", type: :request do
  describe "signing in" do

    before(:each) do
      @user = User.create!(:email => 'test@example.com', :password => 'f4k3p455w0rd')
      @user_profile = UserProfile.create!(first_name: "Horst", last_name: "Hans", user: @user)
      @admin_user = FactoryBot.create(:user, :admin)
      @admin_user_profile = UserProfile.create!(first_name: "Willi", last_name: "Wichtig", user: @admin_user)
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
  
  describe "management" do
    
    before(:each) do
      @user = User.create!(:email => 'test@example.com', :password => 'f4k3p455w0rd')
      @user_profile = UserProfile.create!(first_name: "Horst", last_name: "Hans", user: @user)
      @admin_user = FactoryBot.create(:user, :admin)
      @admin_user_profile = UserProfile.create!(first_name: "Willi", last_name: "Wichtig", user: @admin_user)
     end
     
    it "allows admin user to create a new user" do
      new_user = FactoryBot.build(:user_profile)
      sign_in @admin_user
      visit 'user_profile'
      click_link('List all User Profiles')
      click_link('New User Profile')
      fill_in 'user_profile_first_name', with: new_user.first_name
      fill_in 'user_profile_last_name', with: new_user.last_name
      fill_in 'user_profile_user_attributes_email', with: new_user.user.email
      fill_in 'user_profile_user_attributes_password', with: new_user.user.password
      fill_in 'user_profile_user_attributes_password_confirmation', with: new_user.user.password
      click_button('Create User profile')
      expect(page).to have_content(new_user.user.email)
    end
  end
end
