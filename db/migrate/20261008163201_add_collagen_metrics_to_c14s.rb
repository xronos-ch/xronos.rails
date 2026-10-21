# frozen_string_literal: true

class AddCollagenMetricsToC14s < ActiveRecord::Migration[8.0]
  def change
    add_column :c14s, :carbon_proportion, :float
    add_column :c14s, :carbon_nitrogen_ratio, :float
  end
end
