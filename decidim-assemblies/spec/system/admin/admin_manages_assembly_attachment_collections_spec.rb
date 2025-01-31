# frozen_string_literal: true

require "spec_helper"

describe "Admin manages assembly attachment collections examples" do
  include_context "when admin administrating an assembly"

  let(:collection_for) { assembly }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_assemblies.edit_assembly_path(assembly)
    within_admin_sidebar_menu do
      click_link "Attachments"
    end
    click_link "Folders"
  end

  it_behaves_like "manage attachment collections examples"
end
