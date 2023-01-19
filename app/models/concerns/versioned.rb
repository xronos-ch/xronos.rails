module Versioned

  extend ActiveSupport::Concern

  included do # instance methods
    has_paper_trail meta: { revision_comment: :revision_comment }

    attr_accessor :revision_comment
    validates :revision_comment, presence: true
  end

  class_methods do
  end

end
