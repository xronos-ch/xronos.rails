class AddPublicEmailToUserProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :user_profiles, :public_email, :string
  end
end
