class AddFullNameToUserProfiles < ActiveRecord::Migration[7.0]
  def change
    remove_column :user_profiles, :first_name, :string
    remove_column :user_profiles, :last_name, :string
    add_column :user_profiles, :full_name, :string
  end
end
