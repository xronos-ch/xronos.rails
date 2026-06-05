module Versioned

  extend ActiveSupport::Concern

  included do # instance methods
    has_paper_trail meta: { revision_comment: :revision_comment }

    attr_accessor :revision_comment
    #validates :revision_comment, presence: true

    # N.B. doesn't work for destroy_async, use destroy_async_with_paper_trail
    # instead
    before_destroy :propagate_revision_comment_to_dependents

    # Keep track of async associations for metaprogramming
    class_attribute :async_destroy_associations, default: []
  end

  class_methods do
    ##
    # Replicates `dependent: destroy_async` but preserving PaperTrail metadata
    # 
    def destroy_async_with_paper_trail(association, job: DestroyAsyncWithPaperTrailJob, batch_size: 500)
      self.async_destroy_associations += [association.to_sym]

      after_destroy_commit do
        Versioned.enqueue(
          parent: self,
          association: association,
          job: job,
          batch_size: batch_size
        )
      end
    end
  end

  def self.enqueue(parent:, association:, job:, batch_size:)
    whodunnit = PaperTrail.request.whodunnit

    job.perform_later(
      parent.class.name,
      parent.id,
      association.to_s,
      whodunnit: whodunnit,
      revision_comment: parent.revision_comment,
      batch_size: batch_size
    )
  end

  private

  def propagate_revision_comment_to_dependents
    return if revision_comment.blank?

    self.class
      .reflect_on_all_associations
      .select do |assoc|
        [:has_many, :has_one].include?(assoc.macro) &&
          assoc.options[:dependent] == :destroy
      end
      .each do |assoc|

        # Fetch the associated object(s)
        associated = public_send(assoc.name)

        # Normalise to an array
        children =
          case assoc.macro
          when :has_one
            associated ? [associated] : []
          when :has_many
            associated.to_a
          else
            []
          end

        children.each do |child|
          next unless child.class.included_modules.include?(Versioned)
          next if child.revision_comment.present?

          child.revision_comment = revision_comment
        end
      end
  end

end
