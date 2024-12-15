# == Schema Information
#
# Table name: dendros
#
#  id           :bigint           not null, primary key
#  description  :text
#  end_year     :integer
#  is_anchored  :boolean          default(FALSE)
#  measurements :jsonb            not null
#  name         :string           not null
#  offset       :integer
#  series_code  :string           not null
#  start_year   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  sample_id    :bigint           not null
#
# Indexes
#
#  index_dendros_on_measurements  (measurements) USING gin
#  index_dendros_on_sample_id     (sample_id)
#  index_dendros_on_series_code   (series_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (sample_id => samples.id)
#
require 'rails_helper'

RSpec.describe Dendro, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
