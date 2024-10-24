class AddTypeToCals < ActiveRecord::Migration[7.0]
  def change
    add_column :cals, :type, :string, index: true
    # There can't be any cals when you run this
    change_column_null :cals, :type, false
    add_index :cals, [ :type, :c14_age, :c14_error, :c14_curve ], unique: true
  end
end
