# == Schema Information
#
# Table name: imports
# Database name: primary
#
#  id              :bigint           not null, primary key
#  error           :text
#  records_created :jsonb
#  records_updated :jsonb
#  success         :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  source_id       :bigint           not null
#
# Indexes
#
#  index_imports_on_source_id  (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (source_id => sources.id)
#
FactoryBot.define do
  factory :import do
    source
    records_created { { "site" => 5, "c14" => 10 } }
    records_updated { { "site" => 2 } }
    success { true }

    trait :failed do
      success { false }
      error { "Something went wrong" }
    end
  end
end
