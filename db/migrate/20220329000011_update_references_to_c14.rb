class UpdateReferencesToC14 < ActiveRecord::Migration[6.1]
  def change
    rename_column :xrons, :c14_measurement_id, :c14_id
  end
end
