# frozen_string_literal: true

require "spec_helper"

describe "Assembly admin accesses admin sections" do
  include_context "when assembly admin administrating an assembly"

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when is a mother assembly" do
    it "can access all sections" do
      visit decidim_admin_assemblies.assemblies_path
      click_link "Configure"

      expect(page).to have_content("Info")
      expect(page).to have_content("Components")
      expect(page).to have_content("Categories")
      expect(page).to have_content("Attachments")
      expect(page).to have_content("Members")
      expect(page).to have_content("Assembly admins")
      expect(page).to have_content("Private users")
      expect(page).to have_content("Moderations")
    end
  end

  context "when is a child assembly" do
    let!(:child_assembly) { create(:assembly, parent: assembly, organization:, hashtag: "child") }

    before do
      visit decidim_admin_assemblies.assemblies_path
      within find("tr", text: translated(assembly.title)) do
        click_link "Assemblies"
      end

      click_link "Configure"
    end

    it "can access all sections" do
      expect(page).to have_content("Info")
      expect(page).to have_content("Components")
      expect(page).to have_content("Categories")
      expect(page).to have_content("Attachments")
      expect(page).to have_content("Members")
      expect(page).to have_content("Assembly admins")
      expect(page).to have_content("Private users")
      expect(page).to have_content("Moderations")
    end

    it_behaves_like "assembly admin manage assembly components"
  end
end
