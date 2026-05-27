# == Schema Information
#
# Table name: functional_classification_confidences
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  rank        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class FunctionalClassificationConfidence < ApplicationRecord
  has_many :functional_classifications, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :rank, presence: true, numericality: { only_integer: true }
end
