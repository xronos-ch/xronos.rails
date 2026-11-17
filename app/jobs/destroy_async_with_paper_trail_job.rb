class DestroyAsyncWithPaperTrailJob < ApplicationJob
  queue_as :default

  def perform(parent_class, parent_id, association, whodunnit:, revision_comment:, batch_size:)
    parent_klass = parent_class.constantize
    reflection   = parent_klass.reflect_on_association(association.to_sym)

    raise ArgumentError, "Unknown association #{association}" unless reflection

    child_klass = reflection.klass
    foreign_key = reflection.foreign_key

    PaperTrail.request(whodunnit: whodunnit) do
      child_klass
        .where(foreign_key => parent_id)
        .find_in_batches(batch_size: batch_size) do |batch|
          batch.each do |child|
            next unless child.class.included_modules.include?(Versioned)

            child.revision_comment = revision_comment
            child.destroy
          end
        end
    end
  end
end
