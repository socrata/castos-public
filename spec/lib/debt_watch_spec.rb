require 'rails_helper'

RSpec.describe DebtWatch do

  context "when getting current column names" do
    it "should return an Array of Hashes" do
      result = VCR.use_cassette('get_current_column_names') do
        DebtWatch.new.send(:current_column_names)
      end

      expect(result.class).to eq Array
      result.each do |r|
        expect(r.class).to eq Hashie::Mash
      end
    end
  end

  context "when getting the column name hash" do
    it "should return correct format" do
      result = VCR.use_cassette('get_current_column_names') do
        DebtWatch.new.send(:column_name_hash)
      end

      expect(result.length).to eq DebtWatch::COLUMN_NAME_FILTER.length
    end
  end

  context "when searching by county" do
    it "should return an array with one value" do
      search_result = VCR.use_cassette('search_by_county') do
        DebtWatch.new.search_by_column(column: "issuer_county", value: "Kern", limit: 1)
      end

      expect(search_result.class).to eq Array
      expect(search_result.length).to eq 1
    end

    it "searching by county should return an array of Issuer names" do
      search_result = VCR.use_cassette('search_issuers_by_county') do
        DebtWatch.new.issuers_by_county("Kern")
      end

      expect(search_result.class).to eq Set
      expect(search_result.length).to be > 1

      search_result.each do |sr|
        expect(sr.class).to eq String
      end
    end
  end

  context "when getting Other Debt Issuance Data" do
    it "should yield a successful response" do
      result = VCR.use_cassette('other_debt_issuance_data') do
        DebtWatch.new.get_other_datasets
      end

      expect(result).to_not be_nil
    end
  end

  context "when searching by wheel path" do
    it "searching by Issuer Group should return an array of Issuer Types" do
      search_result = VCR.use_cassette('search_issuer_types_by_issuer_group') do
        DebtWatch.new.issuer_types_by_issuer_group("Counties")
      end

      expect(search_result.class).to eq Set
      expect(search_result.length).to be > 1

      search_result.each do |sr|
        expect(sr.class).to eq String
      end
    end

    it "searching by issuer_type should return an array of Issuer names" do
      query_term = { issuer_type: "Community Facilities District", issuer_group: "Cities" }

      search_result = VCR.use_cassette('search_issuers_by_issuer_type') do
        DebtWatch.new.issuers_by_issuer_type(query_term)
      end

      expect(search_result.class).to eq Set
      expect(search_result.length).to be > 0

      search_result.each do |sr|
        expect(sr.class).to eq String
      end
    end
  end

  context "when getting debt data for issuers" do
    it "returns a hash of debt data by issuer" do
      search_result = VCR.use_cassette('issuers_debt_data') do
        DebtWatch.new.get_debt_for_issuers(
          issuers: ["Brea", "Riverside"],
          debt_filters: {
            "issuer_group" => "Cities",
            "issuer_type"  => "City Government"
          }
        )
      end

      expect(search_result.class).to eq Array
      expect(search_result.length).to be > 1
    end

    it "filters by issuer_group and issuer_type" do
      search_result = VCR.use_cassette('filtered_issuers_debt_data') do
        DebtWatch.new.get_debt_for_issuers(
          issuers: [
            "The Regents of the University of California",
            "State of California"
          ],
          debt_filters: {
            "issuer_type"  => "State Programs & Department",
            "issuer_group" => "UC & CSU"
          }
        )
      end

      types = search_result.map{ |issuance| issuance["issuer_group_alias"] }.uniq
      expect(types.length).to eq 1
      expect(types.first).to eq "UC & CSU"
    end

    it "limits the returned columns by default" do
      search_result = VCR.use_cassette('limits_returned_columns') do
        DebtWatch.new.get_debt_for_issuers(
          issuers: ["Brea", "Riverside"],
          debt_filters: {
            "issuer_group" => "Cities",
            "issuer_type"  => "City Government"
          }
        )
      end

      expect(search_result.class).to eq Array
      expect(search_result.first.class).to eq Hash
      expect(search_result.first.length).to eq 16
    end
  end

  context "when getting issuer groups" do
    it "returns an array of issuer groups with their debts" do
      result = VCR.use_cassette('issuer_group_wheel') do
        DebtWatch.new.get_issuer_groups
      end
      expect(result.class).to eq Array
      expect(result.length).to be > 1
      result.each do |r|
        expect(r.class).to eq Hash
      end
    end
  end

  context "when using County Map Flyout Data" do
    it "returns a array of county map flyout data" do
      search_result = VCR.use_cassette('county_map_flyout_data') do
        DebtWatch.new.map_info
      end

      expect(search_result.class).to eq Array
      expect(search_result.length).to eq 58
    end
  end

  context "when using Carousel Data" do
    it "returns a array of carousel data" do
      data = VCR.use_cassette('carousel_data') do
        DebtWatch.new.carousel_content
      end

      expect(data.class).to eq Array
    end
  end

  context "when using Landing Page Data" do
    it "returns a array of landing page data" do
      data = VCR.use_cassette('landing_page_data') do
        DebtWatch.new.static_landing_page_content
      end

      expect(data.class).to eq Array
    end
  end

  context "when using Selection Page Data" do
    it "yields a successful response" do
      result = VCR.use_cassette('selection_page_data') do
        DebtWatch.new.selection_page_data
      end

      result.each do |r|
        expect(r.class).to eq Hashie::Mash
      end
    end
  end

  # The Socrata API removes columns with null values from the data returned to
  #   the client, but we _need_ this for CVS generation. We can't use the built
  #   in CVS data response from Socrata because of Angular. We are using 'State
  #   of California' as our Issuer here because we know that currently (9/27/15)
  #   that they have several null fields
  it "inserts empty strings for missing column names" do
    result = VCR.use_cassette('state_of_california') do
      DebtWatch.new.get_debt_for_issuers(
        issuers:      ['State of California'],
        debt_filters: { "issuer_type" => "State" },
        tabular_view: true
      )
    end

    result.each do |r|
      expect(r.length).to eq 59
    end
  end
end
