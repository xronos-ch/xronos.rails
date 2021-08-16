class AddWhodunnitUserEmailToVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :versions, :whodunnit_user_email, :string
  end
end
