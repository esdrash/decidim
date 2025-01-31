# frozen_string_literal: true

require "decidim/initiatives/seeds"

Decidim.register_participatory_space(:initiatives) do |participatory_space|
  participatory_space.icon = "media/images/decidim_initiatives.svg"
  participatory_space.stylesheet = "decidim/initiatives/initiatives"

  participatory_space.context(:public) do |context|
    context.engine = Decidim::Initiatives::Engine
    context.layout = "layouts/decidim/initiative"
  end

  participatory_space.context(:admin) do |context|
    context.engine = Decidim::Initiatives::AdminEngine
    context.layout = "layouts/decidim/admin/initiative"
  end

  participatory_space.participatory_spaces do |organization|
    Decidim::Initiative.where(organization:)
  end

  participatory_space.query_type = "Decidim::Initiatives::InitiativeType"

  participatory_space.breadcrumb_cell = "decidim/initiatives/initiative_dropdown_metadata"

  participatory_space.register_resource(:initiative) do |resource|
    resource.actions = %w(comment)
    resource.permissions_class_name = "Decidim::Initiatives::Permissions"
    resource.model_class_name = "Decidim::Initiative"
    resource.card = "decidim/initiatives/initiative"
    resource.searchable = true
  end

  participatory_space.register_resource(:initiatives_type) do |resource|
    resource.model_class_name = "Decidim::InitiativesType"
    resource.actions = %w(vote create)
  end

  participatory_space.model_class_name = "Decidim::Initiative"
  participatory_space.permissions_class_name = "Decidim::Initiatives::Permissions"

  participatory_space.exports :initiatives do |export|
    export.collection do
      Decidim::Initiative
    end

    export.serializer Decidim::Initiatives::InitiativeSerializer
  end

  participatory_space.seeds do
    Decidim::Initiatives::Seeds.new.call
  end
end
