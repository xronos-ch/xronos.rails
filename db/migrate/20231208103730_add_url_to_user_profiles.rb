class AddUrlToUserProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :user_profiles, :url, :string
  end
end
