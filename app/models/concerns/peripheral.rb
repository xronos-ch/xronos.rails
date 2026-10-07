module Peripheral
  extend ActiveSupport::Concern

  class_methods do
    # Single-parent pattern: revision comments on parent
    # Assumes the model has a `belongs_to` with `touch: true` already declared
    def revision_comment_parent(association_name)
      before_save :set_parent_revision_comment_on_save, if: -> { parent_responds_to_revision_comment?(association_name) }
      before_destroy :set_parent_revision_comment_on_destroy, if: -> { parent_responds_to_revision_comment?(association_name) }

      define_method(:set_parent_revision_comment_on_save) do
        parent = public_send(association_name)
        parent.revision_comment = new_record? ? "Added #{self.class.label}." : "Changed #{self.class.label}."
      end

      define_method(:set_parent_revision_comment_on_destroy) do
        parent = public_send(association_name)
        parent.revision_comment = "Removed #{self.class.label}."
      end

      define_method(:parent_responds_to_revision_comment?) do |assoc|
        parent = public_send(assoc)
        parent&.respond_to?(:revision_comment=)
      end
    end

    # Multi-parent pattern: touch all referencing records on save/destroy
    def touch_referencing_records(association_name)
      after_save :touch_referencing_records_with_revision_comment
      before_destroy :touch_referencing_records_with_revision_comment

      define_method(:touch_referencing_records_with_revision_comment) do
        comment = new_record? ? "Added #{self.class.label}." : "Changed #{self.class.label}."
        public_send(association_name).find_each do |record|
          next unless record.respond_to?(:revision_comment=)
          record.revision_comment = comment
          record.touch
        end
      end
    end
  end
end
