class AddWhodunnitUserIdToSupersessionEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :supersession_events, :whodunnit_user,
                  null: false,
                  foreign_key: { to_table: :users }
  end
end
