class AddUserToMultipleModels < ActiveRecord::Migration[5.2]
  def change
    add_reference :measurements, :user, index: true
    add_foreign_key :measurements, :users
    add_reference :fell_phases, :user, index: true
    add_foreign_key :fell_phases, :users
    add_reference :site_phases, :user, index: true
    add_foreign_key :site_phases, :users
    add_reference :ecochronological_units, :user, index: true
    add_foreign_key :ecochronological_units, :users
    add_reference :typochronological_units, :user, index: true
    add_foreign_key :typochronological_units, :users
    add_reference :periods, :user, index: true
    add_foreign_key :periods, :users
  end
end
