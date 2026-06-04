require 'test_helper'

class ContextTest < ActiveSupport::TestCase

  test "destroying a context destroys its samples" do
    context = create(:context)
    create_list(:sample, 2, context: context)

    assert_dependent_destroy(context, :samples, count: 2)
  end

end
