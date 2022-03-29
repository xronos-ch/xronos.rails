class RenameSitePhaseToContext < ActiveRecord::Migration[6.1]
  def change
    rename_table :site_phases, :contexts
  end
end
