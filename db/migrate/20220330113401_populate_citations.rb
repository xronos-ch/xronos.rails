class PopulateCitations < ActiveRecord::Migration[6.1]
  def change
    execute %(
      INSERT INTO citations 
        (reference_id, citing_type, citing_id) 
      SELECT reference_id, 'c14' AS citing_type, c14_id AS citing_id 
      FROM xrons_references 
      JOIN xrons ON xrons_references.xron_id = xrons.id 
      WHERE c14_id IS NOT NULL
    )

    execute %(
      INSERT INTO citations 
        (reference_id, citing_type, citing_id) 
      SELECT reference_id, 'typo' AS citing_type, typo_id AS citing_id 
      FROM xrons_references 
      JOIN xrons ON xrons_references.xron_id = xrons.id 
      WHERE typo_id IS NOT NULL
    )
  end
end
