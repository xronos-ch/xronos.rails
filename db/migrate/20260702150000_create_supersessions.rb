class CreateSupersessions < ActiveRecord::Migration[8.0]
  def change # rubocop:disable Metrics/MethodLength
    create_table :supersessions do |t|
      t.references :superseded,
                  polymorphic: true,
                  null: false,
                  index: {
                    unique: true,
                    name: 'index_supersessions_unique_superseded'
                  }
      t.references :superseded_by, polymorphic: true, null: false
      t.timestamps
    end
  end
end
