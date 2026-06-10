# == Schema Information
#
# Table name: contexts
# Database name: primary
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_id           :integer
#
# Indexes
#
#  index_contexts_on_name     (name)
#  index_contexts_on_site_id  (site_id)
#
require 'test_helper'

class ContextTest < ActiveSupport::TestCase

  test "destroying a context destroys its samples" do
    context = create(:context)
    create_list(:sample, 2, context: context)

    assert_dependent_destroy(context, :samples, count: 2)
  end

end
