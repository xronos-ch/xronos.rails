# lib/xronos/destroy_tree.rb
require "set"

module Xronos
  module DestroyTree
    module_function

    # ------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------
    #
    # Prints a destroy tree for a single root record and returns
    # the total number of dependent records (sync + async).
    #
    def print_destroy_tree_and_count(record)
      puts "#{record.class.name} ##{record.id}"
      walk_sets([record], indent: "")
    end

    # ------------------------------------------------------------
    # Internal: set-based recursion
    # ------------------------------------------------------------

    def walk_sets(records, indent:)
      return 0 if records.empty?

      total = 0
      klass = records.first.class

      children_by_class = collect_children_by_class(records)

      children_by_class.each_with_index do |(child_class, data), index|
        records_for_class = data[:records]
        async             = data[:async]

        print_branch(
          indent: indent,
          index: index,
          total: children_by_class.size,
          label: child_class.name.underscore.pluralize,
          count: records_for_class.size,
          async: async
        )

        total += records_for_class.size

        total += walk_sets(
          records_for_class,
          indent: indent + "│  "
        )
      end

      total
    end

    # ------------------------------------------------------------
    # Internal: collect children across ALL parents, grouped by class
    # ------------------------------------------------------------

    def collect_children_by_class(records)
      klass = records.first.class
      children_by_class = Hash.new { |h, k| h[k] = { records: [], async: false } }

      destroy_associations_for(klass).each do |assoc, async|
        records.each do |record|
          children =
            case assoc.macro
            when :has_one
              r = record.public_send(assoc.name)
              r ? [r] : []
            when :has_many
              record.public_send(assoc.name).to_a
            end

          children.each do |child|
            entry = children_by_class[child.class]
            entry[:records] << child
            entry[:async] ||= async
          end
        end
      end

      children_by_class
    end

    # ------------------------------------------------------------
    # Internal: determine which associations participate in destruction
    # ------------------------------------------------------------

    def destroy_associations_for(klass)
      assocs = []

      # dependent: :destroy / :destroy_async
      klass
        .reflect_on_all_associations
        .select { |a| [:has_many, :has_one].include?(a.macro) }
        .each do |assoc|
          case assoc.options[:dependent]
          when :destroy
            assocs << [assoc, false]
          when :destroy_async
            assocs << [assoc, true]
          end
        end

      # async_destroy_associations (class-level)
      if klass.respond_to?(:async_destroy_associations)
        klass.async_destroy_associations.each do |name|
          assoc = klass.reflect_on_association(name)
          assocs << [assoc, true] if assoc
        end
      end

      assocs
    end

    # ------------------------------------------------------------
    # Internal: output formatting only
    # ------------------------------------------------------------

    def print_branch(indent:, index:, total:, label:, count:, async:)
      branch = index == total - 1 ? "└─" : "├─"
      marker = async ? " *" : ""

      puts "#{indent}#{branch} #{label} (#{count})#{marker}"
    end
  end
end
