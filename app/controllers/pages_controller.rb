class PagesController < ApplicationController
  # Coordinates all traffic to the Landing Page.
  def landing_page
  end

  # Coordinates all traffic to the Issuer Selection page and Comparison Tool page.
  # This includes when navigated from the Map selector or the Donut selector.
  def comparison_tool
    @show_header_links = true
  end
end
