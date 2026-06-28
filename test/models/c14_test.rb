# == Schema Information
#
# Table name: c14s
# Database name: primary
#
#  id             :bigint           not null, primary key
#  bp             :integer
#  cal_bp         :integer
#  cal_std        :integer
#  delta_15n      :float
#  delta_c13      :float
#  delta_c13_std  :float
#  lab_identifier :string
#  method         :string
#  std            :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  c14_lab_id     :bigint
#  sample_id      :bigint
#
# Indexes
#
#  index_c14s_on_c14_lab_id      (c14_lab_id)
#  index_c14s_on_lab_identifier  (lab_identifier)
#  index_c14s_on_method          (method)
#  index_c14s_on_sample_id       (sample_id)
#
require "test_helper"

class C14Test < ActiveSupport::TestCase

  test "destroying a c14 destroys its citations" do
    c14 = create(:c14, :with_citations, citations_count: 2)
    assert_dependent_destroy(c14, :citations, count: 2)
  end

end
