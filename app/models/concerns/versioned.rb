module Versioned

  extend ActiveSupport::Concern

  included do # instance methods
    has_paper_trail on: [:create, :update, :destroy, :touch],
      meta: {
        revision_comment: :revision_comment,
        snapshot_id: :create_peripheral_snapshot
      }

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

  def create_peripheral_snapshot
    return nil unless self.class.respond_to?(:snapshot_children_proc) && self.class.snapshot_children_proc

    snapshot = create_snapshot!(
      identifier: "v#{self.class.base_class.model_name.singular}:#{id}:#{Time.current.to_f}",
      metadata: { source: :paper_trail }
    )
    snapshot.id
  rescue => e
    Rails.logger.warn "Failed to create peripheral snapshot for #{self.class.name}##{id}: #{e.message}"
    nil
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
