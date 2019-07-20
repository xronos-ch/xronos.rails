class RemoveCulturesAndPhasesModels < ActiveRecord::Migration[5.2]
  def change
    drop_table(:cultures)
    drop_table(:phases)
  end
end
