class Chron < ApplicationRecord
  self.abstract_class = true

  # Each Chron subclass needs its own duplicate-detection attribute
  # lists; without this hook all subclasses would share the parent's
  # arrays, and `exact_duplicates_on` calls would accumulate across
  # them.
  def self.inherited(subclass)
    super
    subclass._exact_duplicates_attrs_list = []
    subclass._potential_duplicates_attrs_list = []
  end

  include Versioned
  include Supersedable
  include Mergeable

  belongs_to :sample
  delegate :context, to: :sample
  delegate :site, to: :sample

  has_many :citations, as: :citing, dependent: :destroy
  has_many :references, through: :citations

  after_save :merge_exact_duplicates

  before_merge :reassign_citations!

  acts_as_copy_target

  def self.label
    raise NotImplementedError, "#{name} must implement .label"
  end

  def self.icon
    raise NotImplementedError, "#{name} must implement .icon"
  end

  private

  def reassign_citations!
    Citation.reassign_all_to!(from: self, to: canonical)
  end
end
