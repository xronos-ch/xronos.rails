# == Schema Information
#
# Table name: dendros
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  anchor_position      :integer
#  anchor_year          :integer
#  death_year           :integer
#  description          :text
#  first_year           :integer
#  is_anchored          :boolean
#  last_year            :integer
#  measurement_unit     :string
#  measurement_variable :string
#  measurements         :jsonb            not null
#  name                 :string           not null
#  object_description   :text
#  object_dimensions    :jsonb
#  object_title         :string
#  object_type          :string
#  parameters           :jsonb
#  pith_year            :integer
#  project_end_date     :datetime
#  project_objective    :text
#  project_start_date   :datetime
#  project_title        :string
#  series_code          :string           not null
#  waney_edge           :boolean
#  wood_completeness    :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  chronology_id        :bigint
#  sample_id            :bigint           not null
#
# Indexes
#
#  index_dendros_on_chronology_id  (chronology_id)
#  index_dendros_on_measurements   (measurements) USING gin
#  index_dendros_on_sample_id      (sample_id)
#  index_dendros_on_series_code    (series_code)
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

    measurements { (1..10).map { |position| { position: position, value: 1.25 } } }

    trait :anchored do
      is_anchored { true }
      anchor_position { 1 }
      anchor_year { 1246 }
    end

    sample
  end
end
