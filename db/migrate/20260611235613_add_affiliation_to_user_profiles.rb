class AddAffiliationToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :affiliation, :text
  end
end
