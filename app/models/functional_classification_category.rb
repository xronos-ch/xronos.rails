

# == Schema Information
#
# Table name: functional_classification_categories
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class FunctionalClassificationCategory < ApplicationRecord
  has_many :functional_classifications, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
