class AddOrcidToUserProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :user_profiles, :orcid, :string
  end
end
