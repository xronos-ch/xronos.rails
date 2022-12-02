class CorrectCitingTypeInCitationsAgain < ActiveRecord::Migration[6.1]
  def change
    execute %(
      UPDATE citations
      SET citing_type = 'C14'
      WHERE citing_type = 'c14'
    )
    execute %(
      UPDATE citations
      SET citing_type = 'Typo'
      WHERE citing_type = 'typo'
    )
    execute %(
      UPDATE citations
      SET citing_type = 'Site'
      WHERE citing_type = 'site'
    )
  end
end
