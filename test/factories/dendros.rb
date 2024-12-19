# == Schema Information
#
# Table name: dendros
#
#  id                 :bigint           not null, primary key
#  death_year         :integer
#  description        :text
#  end_year           :integer
#  first_year         :integer
#  is_anchored        :boolean          default(FALSE)
#  last_year          :integer
#  measurements       :jsonb            not null
#  name               :string           not null
#  object_description :text
#  object_dimensions  :jsonb
#  object_title       :string
#  object_type        :string
#  offset             :integer
#  parameters         :jsonb
#  pith_year          :integer
#  project_end_date   :datetime
#  project_objective  :text
#  project_start_date :datetime
#  project_title      :string
#  series_code        :string           not null
#  start_year         :integer
#  waney_edge         :boolean
#  wood_completeness  :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  chronology_id      :bigint
#  sample_id          :bigint           not null
#
# Indexes
#
#  index_dendros_on_chronology_id  (chronology_id)
#  index_dendros_on_measurements   (measurements) USING gin
#  index_dendros_on_sample_id      (sample_id)
#  index_dendros_on_series_code    (series_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (chronology_id => chronologies.id)
#  fk_rails_...  (sample_id => samples.id)
#
FactoryBot.define do
  factory :dendro do
    series_code { Faker::Alphanumeric.unique.alphanumeric(number: 10).upcase }
    name { Faker::Science.element }
    description { Faker::Lorem.paragraph }
    start_year { Faker::Number.between(from: -5000, to: 1950) }
    end_year { start_year + Faker::Number.between(from: 10, to: 300) }
    is_anchored { [true, false].sample }
    offset { Faker::Number.between(from: 0, to: 10) }
    measurements { Array.new(10) { { year: Faker::Number.number(digits: 4), value: Faker::Number.decimal(l_digits: 1, r_digits: 2) } } }
    
    sample
  end
end
