require "test_helper"

class SampleTest < ActiveSupport::TestCase

  test "destroying a sample destroys its c14s" do
    sample = create(:sample)
    create_list(:c14, 2, sample: sample)

    assert_dependent_destroy(sample, :c14s, count: 2)
  end

  test "destroying a sample destroys its typos" do
    sample = create(:sample)
    create_list(:typo, 2, sample: sample)

    assert_dependent_destroy(sample, :typos, count: 2)
  end

end
