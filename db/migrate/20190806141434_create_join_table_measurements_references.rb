class CreateJoinTableMeasurementsReferences < ActiveRecord::Migration[5.2]
  def change
    create_join_table :measurements, :references do |t|
      t.index [:measurement_id, :reference_id], name: :index_mr
    end
  end
end
