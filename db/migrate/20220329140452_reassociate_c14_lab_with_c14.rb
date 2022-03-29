class ReassociateC14LabWithC14 < ActiveRecord::Migration[6.1]
  def change
    add_reference :c14s, :c14_lab
    execute %(
      UPDATE c14s
      SET c14_lab_id = xrons.lab_id
      FROM xrons
      WHERE c14s.id = xrons.c14_id
      AND xrons.c14_id IS NOT NULL
    )
    remove_reference :xrons, :lab
  end
end
