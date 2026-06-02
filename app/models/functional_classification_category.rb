

# == Schema Information
#
# Table name: functional_classification_categories
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class FunctionalClassificationCategory < ApplicationRecord
  has_many :functional_classifications, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
