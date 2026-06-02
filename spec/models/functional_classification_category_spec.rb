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

require 'rails_helper'

RSpec.describe FunctionalClassificationCategory, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
