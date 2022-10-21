# frozen_string_literal: true

module Decidim
  module Meetings
    # Custom helpers, scoped to the meetings engine.
    #
    module Directory
      module ApplicationHelper
        include PaginateHelper
        include Decidim::MapHelper
        include Decidim::Meetings::MapHelper
        include Decidim::Meetings::MeetingsHelper
        include Decidim::Comments::CommentsHelper
        include Decidim::SanitizeHelper
        include Decidim::CheckBoxesTreeHelper
        include Decidim::IconHelper
        include Decidim::FiltersHelper

        def filter_type_values
          type_values = Decidim::Meetings::Meeting::TYPE_OF_MEETING.map { |type| [type, filter_text_for(type, t(type, scope: "decidim.meetings.meetings.filters.type_values"))] }
          type_values.prepend(["all", filter_text_for("all", t("decidim.meetings.meetings.filters.type_values.all"))])
        end

        def filter_date_values
          ["all", "upcoming", "past"].map { |k| [k, filter_text_for(k, t(k, scope: "decidim.meetings.meetings.filters.date_values"))] }
        end

        def directory_filter_scopes_values
          main_scopes = current_organization.scopes.top_level

          scopes_values = main_scopes.includes(:scope_type, :children).flat_map do |scope|
            TreeNode.new(
              TreePoint.new(scope.id.to_s, translated_attribute(scope.name, current_organization)),
            scope_children_to_tree(scope)
            )
          end

          scopes_values.prepend(TreePoint.new("global", t("decidim.scopes.global")))

          TreeNode.new(
            TreePoint.new("", t("decidim.meetings.application_helper.filter_scope_values.all")),
          scopes_values
          )
        end

        def scope_children_to_tree(scope)
          return unless scope.children.any?

          scope.children.includes(:scope_type, :children).flat_map do |child|
            TreeNode.new(
              TreePoint.new(child.id.to_s, translated_attribute(child.name, current_organization)),
            scope_children_to_tree(child)
            )
          end
        end

        def directory_meeting_spaces_values
          participatory_spaces = current_organization.public_participatory_spaces

          spaces = participatory_spaces.collect(&:model_name).uniq.map { |participatory_space| [participatory_space.name.underscore, filter_text_for(participatory_space.name, participatory_space.human(count: 2))] }

          spaces.prepend(["all", filter_text_for("all", t("decidim.meetings.application_helper.filter_meeting_space_values.all"))])
        end

        def directory_filter_categories_values
          participatory_spaces = current_organization.public_participatory_spaces
          list_of_ps = participatory_spaces.flat_map do |current_participatory_space|
            next unless current_participatory_space.respond_to?(:categories)

            sorted_main_categories = current_participatory_space.categories.first_class.includes(:subcategories).sort_by do |category|
              [category.weight, translated_attribute(category.name, current_organization)]
            end

            categories_values = categories_values(sorted_main_categories)

            next if categories_values.empty?

            key_point = current_participatory_space.class.name.gsub("::", "__") + current_participatory_space.id.to_s

            TreeNode.new(
              TreePoint.new(key_point, translated_attribute(current_participatory_space.title, current_organization)),
              categories_values
            )
          end

          list_of_ps.compact!
          TreeNode.new(
            TreePoint.new("", t("decidim.meetings.application_helper.filter_category_values.all")),
            list_of_ps
          )
        end

        def directory_filter_origin_values
          origin_values = ["all", "official", "participants"]
          origin_values << "user_groups" if current_organization.user_groups_enabled?
          origin_values.map { |k| [k, filter_text_for(k, t(k, scope: "decidim.meetings.meetings.filters.origin_values"))] }
        end

        # Options to filter meetings by activity.
        def activity_filter_values
          ["all", "my_meetings"].map { |k| [k, filter_text_for(k, t(k, scope: "decidim.meetings.meetings.filters"))] }
        end

        # def filter_text_for(name, translation)
        #   text = ""
        #   text += resource_type_icon name
        #   text += content_tag :span, translation
        #   text.html_safe
        # end

        protected

        def categories_values(sorted_main_categories)
          sorted_main_categories.flat_map do |category|
            sorted_descendant_categories = category.descendants.includes(:subcategories).sort_by do |subcategory|
              [subcategory.weight, translated_attribute(subcategory.name, current_organization)]
            end

            subcategories = sorted_descendant_categories.flat_map do |subcategory|
              TreePoint.new(subcategory.id.to_s, translated_attribute(subcategory.name, current_organization))
            end

            TreeNode.new(
              TreePoint.new(category.id.to_s, translated_attribute(category.name, current_organization)),
              subcategories
            )
          end
        end
      end
    end
  end
end
