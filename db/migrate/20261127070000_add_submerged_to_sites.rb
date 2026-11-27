# frozen_string_literal: true

# Lets editors mark submerged sites so valid locations can be excluded from water findings.
class AddSubmergedToSites < ActiveRecord::Migration[8.0]
  def change
    add_column :sites, :submerged, :boolean, default: false, null: false
  end
end
