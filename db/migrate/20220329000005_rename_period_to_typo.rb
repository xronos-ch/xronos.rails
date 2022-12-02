class RenamePeriodToTypo < ActiveRecord::Migration[6.1]
  def change
    rename_table :periods, :typos
  end
end
