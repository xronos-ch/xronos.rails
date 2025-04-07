# == Schema Information
#
# Table name: c14_lab_codes
#
#  id         :bigint           not null, primary key
#  canonical  :boolean          not null
#  lab_code   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  c14_lab_id :bigint
#
# Indexes
#
#  index_c14_lab_codes_on_c14_lab_id  (c14_lab_id)
#  index_c14_lab_codes_on_lab_code    (lab_code)
#
# Foreign Keys
#
#  fk_rails_...  (c14_lab_id => c14_labs.id)
#
FactoryBot.define do
  
  factory :c14_lab_code do
    lab_code { c14_lab.name.delete(" -").chars.sample(3).join.humanize }
    canonical { false }
  end
  
end
