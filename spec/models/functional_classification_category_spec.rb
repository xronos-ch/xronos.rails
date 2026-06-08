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

require 'rails_helper'

RSpec.describe FunctionalClassificationCategory, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
