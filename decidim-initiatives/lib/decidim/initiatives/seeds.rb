# frozen_string_literal: true

require "decidim/seeds"

module Decidim
  module Initiatives
    class Seeds < Decidim::Seeds
      def call
        organization = Decidim::Organization.first

        Decidim::ContentBlock.create(
          organization:,
          weight: 33,
          scope_name: :homepage,
          manifest_name: :highlighted_initiatives,
          published_at: Time.current
        )

        3.times do |n|
          type = Decidim::InitiativesType.create!(
            title: Decidim::Faker::Localized.sentence(word_count: 5),
            description: Decidim::Faker::Localized.sentence(word_count: 25),
            organization:,
            banner_image: ::Faker::Boolean.boolean(true_ratio: 0.5) ? banner_image : nil # Keep after organization
          )

          organization.top_scopes.each do |scope|
            Decidim::InitiativesTypeScope.create(
              type:,
              scope:,
              supports_required: (n + 1) * 1000
            )
          end
        end

        Decidim::Initiative.states.keys.each do |state|
          Decidim::Initiative.skip_callback(:save, :after, :notify_state_change, raise: false)
          Decidim::Initiative.skip_callback(:create, :after, :notify_creation, raise: false)

          params = {
            title: Decidim::Faker::Localized.sentence(word_count: 3),
            description: Decidim::Faker::Localized.sentence(word_count: 25),
            scoped_type: Decidim::InitiativesTypeScope.reorder(Arel.sql("RANDOM()")).first,
            state:,
            signature_type: "online",
            signature_start_date: Date.current - 7.days,
            signature_end_date: Date.current + 7.days,
            published_at: 7.days.ago,
            author: Decidim::User.reorder(Arel.sql("RANDOM()")).first,
            organization:
          }

          initiative = Decidim.traceability.perform_action!(
            "publish",
            Decidim::Initiative,
            organization.users.first,
            visibility: "all"
          ) do
            Decidim::Initiative.create!(params)
          end
          initiative.add_to_index_as_search_resource

          Decidim::Comments::Seed.comments_for(initiative)

          create_attachment(attached_to: initiative, filename: "city.jpeg")

          Decidim::Initiatives.default_components.each do |component_name|
            component = Decidim::Component.create!(
              name: Decidim::Components::Namer.new(initiative.organization.available_locales, component_name).i18n_name,
              manifest_name: component_name,
              published_at: Time.current,
              participatory_space: initiative
            )

            next unless component_name.in? ["pages", :pages]

            Decidim::Pages::CreatePage.call(component) do
              on(:invalid) { raise "Cannot create page" }
            end
          end
        end
      end
    end
  end
end
