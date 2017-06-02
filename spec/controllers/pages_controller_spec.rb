require 'rails_helper'

RSpec.describe PagesController, type: :controller do

  context "Landing Page" do
    it "successfully returns a response" do
      get :landing_page
      expect(response).to be_successful
    end
  end

  context "Comparison Tool" do
    it "successfully returns a response" do
      get :comparison_tool
      expect(response).to be_successful
    end
  end
end
