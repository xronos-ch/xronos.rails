class ReassociateXrons < ActiveRecord::Migration[6.1]
  def change
    # Removes the need for a "xrons" model by:
    # 1. Reassociating c14s, dendros, and typos directly with samples
    # 2. Reassociating references with c14s, dendros, and typos through a
    #    polymorphic "citation" join table
    add_reference :c14s, :sample
    execute %(
      UPDATE c14s 
      SET sample_id = xrons.sample_id 
      FROM xrons 
      WHERE c14s.id = xrons.c14_id;
    )

    add_reference :typos, :sample
    execute %(
      UPDATE typos 
      SET sample_id = xrons.sample_id 
      FROM xrons 
      WHERE typos.id = xrons.typo_id;
    )

    create_table :citations do |t|
      t.belongs_to :reference
      t.references :citing, polymorphic: true
    end
  end
end
