class CorrectCitingTypeInCitations < ActiveRecord::Migration[6.1]
  def change
    execute %(
      UPDATE citations
      SET citing_type = 'C14'
      WHERE citing_type = 'c14'
    )
  end
end
