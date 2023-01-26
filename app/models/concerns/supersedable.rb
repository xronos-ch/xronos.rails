module Supersedable

  extend ActiveSupport::Concern

  included do # instance methods
    def supersedable?
      true
    end

    def superseded?
      superseded_by.present?
    end

    def reassign_associations(revision_comment = nil)
      unless superseded?
        raise "Attempt to reassign associations of record that is not superseded."
      end

      assocs = self.class.supersedable_associations
      assocs.each do |assoc,reflection|
        unless reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
          reassign_association(reflection, revision_comment)
        else
          reassign_many_to_many_association(reflection, revision_comment)
        end
      end

      return true
    end

    protected

    def reassign_association(reflection, revision_comment = nil)
      revision_comment ||= default_revision_comment

      foreign_key = self.class.foreign_key_for_reflection(reflection)
      children = self.send(reflection.name)

      children.each do |child|
        child.write_attribute(foreign_key, self.superseded_by)
        child.revision_comment = revision_comment
        child.save!
      end
    end

    def reassign_many_to_many_association(reflection, revision_comment = nil)
      revision_comment ||= default_revision_comment
      # TODO
    end

    private

    def default_revision_comment
      self.class.model_name.singular + 
        ":" +
        self.id.to_s +
        " has been superseded by " + 
        self.class.model_name.singular +
        ":" + 
        self.superseded_by.to_s
    end

  end

  class_methods do
    def supersedable_associations
      reflections
        .filter { |k,v| k != "versions" } # never reassign paper_trail!
        .filter { |k,v| k != "pg_search_document" } # shouldn't have one if superseded
        .filter { |k,v| 
          v.is_a?(ActiveRecord::Reflection::HasOneReflection) ||
          v.is_a?(ActiveRecord::Reflection::HasManyReflection) ||
          v.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)
        }
    end

    def foreign_key_for_reflection(reflection)
      
      unless reflection.options.has_key?(:as)
        foreign_key = model_name.param_key + "_id"
      else
        foreign_key = reflection.options[:as].to_s + "_id"
      end
    end

  end

end
