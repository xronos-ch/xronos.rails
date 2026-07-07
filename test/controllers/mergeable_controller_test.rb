# frozen_string_literal: true

require "test_helper"

# --- Same-sample test models ---

class Thing < ApplicationRecord
  include Mergeable

  exact_duplicates_on :name

  after_save :merge_exact_duplicates
end

class ThingsController < ApplicationController
  before_action :set_thing, only: [:update]
  include MergeableController

  def update
    if @thing.update(thing_params)
      render plain: "ok", status: :ok
    else
      render plain: "error", status: :unprocessable_entity
    end
  end

  private

  def set_thing
    @thing = Thing.find(params[:id])
  end

  def thing_params
    params.require(:thing).permit(:name)
  end
end

# --- Cross-sample test models ---

class ChronSample < ApplicationRecord
  has_many :chron_things, foreign_key: :chron_sample_id

  def name_relaxed_duplicate_of?(other)
    return false unless other.is_a?(self.class) && id != other.id
    return false unless name.nil? && other.name.nil? || name == other.name

    true
  end
end

class ChronThing < ApplicationRecord
  include Mergeable

  exact_duplicates_on :name, :chron_sample_id

  after_save :merge_exact_duplicates

  belongs_to :chron_sample, optional: false

  def find_cross_sample_duplicate
    chron_attrs = self.class.exact_duplicates_attrs - [:chron_sample_id]
    strict_attrs = chron_attrs - self.class.exact_duplicates_nil_matches_nil
    return nil if strict_attrs.any? { |a| send(a).nil? }

    conditions = chron_attrs.index_with { |a| send(a) }

    self.class.includes(:chron_sample)
      .where(conditions)
      .where.not(id: id)
      .where.not(chron_sample_id: chron_sample_id)
      .find { |c| chron_sample&.name_relaxed_duplicate_of?(c.chron_sample) }
  end
end

class ChronThingsController < ApplicationController
  before_action :set_chron_thing, only: [:update]
  include MergeableController

  def update
    if @chron_thing.update(thing_params)
      render plain: "ok", status: :ok
    else
      render plain: "error", status: :unprocessable_entity
    end
  end

  private

  def set_chron_thing
    @chron_thing = ChronThing.find(params[:id])
  end

  def thing_params
    params.require(:chron_thing).permit(:name, :chron_sample_id)
  end
end

class MergeableControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :things, force: true do |t|
          t.string :name
          t.timestamps
        end

        create_table :chron_samples, force: true do |t|
          t.string :name
          t.timestamps
        end

        create_table :chron_things, force: true do |t|
          t.string :name
          t.integer :chron_sample_id
          t.timestamps
        end
      end
    end

    Rails.application.routes.disable_clear_and_finalize = true
    Rails.application.routes.draw do
      resources :things, only: [:update]
      resources :chron_things, only: [:update]
    end

    @canon = Thing.create!(name: "Canonical")
    @other = Thing.create!(name: "Other")

    @sample_a = ChronSample.create!(name: "Match")
    @sample_b = ChronSample.create!(name: "Match")
    @chron_a = ChronThing.create!(name: "Unique", chron_sample: @sample_a)
    @chron_b = ChronThing.create!(name: "Duplicate", chron_sample: @sample_b)
  end

  teardown do
    Rails.application.routes.disable_clear_and_finalize = false
    Rails.application.routes_reloader.reload!
  end

  # --- Same-sample tests ---

  test "update with unique values proceeds normally without merge confirmation" do
    patch thing_path(@other), params: { thing: { name: "Unique" } }

    assert_response :ok
    assert_equal "Unique", @other.reload.name
    assert_equal 2, Thing.count
  end

  test "update that would create a duplicate returns conflict and does not merge" do
    assert_equal 2, Thing.count

    patch thing_path(@other, format: :json), params: { thing: { name: "Canonical" } }

    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "merge_pending", json["error"]
    assert_equal @canon.id, json["duplicate_id"]
    assert_equal 2, Thing.count
  end

  test "update with confirm_merge proceeds with merge" do
    assert_equal 2, Thing.count

    patch thing_path(@other), params: { thing: { name: "Canonical" }, confirm_merge: true }

    assert_response :ok
    assert_equal 1, Thing.count
    assert_equal @canon.id, Thing.first.id
  end

  # --- Cross-sample tests ---

  test "update that would create a cross-sample duplicate returns conflict and does not merge" do
    assert_equal 2, ChronThing.count

    patch chron_thing_path(@chron_a, format: :json),
          params: { chron_thing: { name: "Duplicate" } }

    assert_response :conflict
    json = JSON.parse(response.body)
    assert_equal "merge_pending", json["error"]
    assert_equal @chron_b.id, json["duplicate_id"]
    assert_equal 2, ChronThing.count
  end

  test "update that would create a cross-sample duplicate with confirm_merge saves the record" do
    assert_equal 2, ChronThing.count

    patch chron_thing_path(@chron_a),
          params: { chron_thing: { name: "Duplicate" }, confirm_merge: true }

    assert_response :ok
    assert_equal "Duplicate", @chron_a.reload.name
  end
end
