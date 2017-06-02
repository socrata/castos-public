require 'rails_helper'

RSpec.describe Api::V1::ApiController, type: :controller do

  before(:each) do
    Rails.cache.clear
  end

  context "Landing Page Info" do
    it "returns data for landing page (map, carousel & static)" do
      VCR.use_cassette('api_landing_page_calls') do
        get :landing_page_info
      end

      json_body = JSON.parse(response.body)
      county_info              = json_body["county_info"]
      carousel_data            = json_body["carousel_content"]
      static_data              = json_body["landing_page_content"]
      issuer_group_data        = json_body["issuer_group_wheel"]
      other_debt_issuance_data = json_body["other_debt_issuance_data"]

      expect(county_info.class).to eq Array
      expect(county_info.length).to eq 58
      expect(Rails.cache.read("county_map_info")).to_not be_empty

      expect(carousel_data.class).to eq Array
      expect(carousel_data).to_not be_empty
      expect(Rails.cache.read("carousel_content")).to_not be_empty

      expect(static_data.class).to eq Array
      expect(static_data).to_not be_empty
      expect(Rails.cache.read("landing_page_content")).to_not be_empty

      expect(issuer_group_data.class).to eq Array
      expect(issuer_group_data).to_not be_empty
      expect(Rails.cache.read("issuer_group_wheel")).to_not be_empty

      expect(other_debt_issuance_data).to_not be_nil
    end

    context "when there is an error fetching one of the datasets" do
      it "handles errors correctly" do
        allow_any_instance_of(DebtWatch).to receive(:map_info).and_raise("Boom")
        VCR.use_cassette('api_landing_page_calls') do
          get :landing_page_info
        end

        expect(JSON.parse(response.body)["error"]).to eq "Boom"
        expect(Rails.cache.read("county_map_info")).to be_nil
      end
    end

  end

  context "Issuer Types by Issuer Group" do
    it "returns a list of issuer types by issuer group" do
      VCR.use_cassette('search_issuer_types_by_issuer_group') do
        get :issuer_types_by_issuer_group, issuer_group: "Counties"
      end

      issuer_types = JSON.parse(response.body)["issuer_types"]
      static_data  = JSON.parse(response.body)["static_data"]

      expect(response).to be_successful
      expect(static_data).to_not be_nil
      expect(issuer_types.class).to eq Array
      expect(issuer_types.length).to be > 1
    end
  end

  context "Issuers by Issuer type" do
    it "returns a list of issuers by issuer type" do
      VCR.use_cassette('search_issuers_by_issuer_type') do
        get :issuers_by_issuer_type,
            issuer_group: "Cities",
            issuer_type:  "Community Facilities District"
      end

      issuers     = JSON.parse(response.body)["issuers"]
      static_data = JSON.parse(response.body)["static_data"]

      expect(response).to be_successful
      expect(static_data).to_not be_nil
      expect(issuers.class).to eq Array
      expect(issuers.length).to be > 0
      expect(Rails.cache.read("Community Facilities District_Cities_issuer_data")).to_not be_empty
    end
  end

  context "Issuers by County" do
    it "returns a list of issuers by county" do
      VCR.use_cassette('search_issuers_by_county') do
        get :issuers_by_county, county: "Kern"
      end

      issuers      = JSON.parse(response.body)["issuers"]
      static_data  = JSON.parse(response.body)["static_data"]

      expect(response).to be_successful
      expect(static_data).to_not be_nil
      expect(issuers.class).to eq Array
      expect(issuers.length).to be > 1
      expect(Rails.cache.read("Kern_issuer_data")).to_not be_empty
    end
  end

  context "Bulk Issuer Data" do
    it "successfully returns a response" do
      VCR.use_cassette('issuers_debt_data') do
        get :bulk_issuer_data,
            issuers:      ["Brea", "Riverside"],
            debt_filters: {
              "issuer_group" => "Cities",
              "issuer_type"  => "City Government"
            }
      end

      results = JSON.parse(response.body)

      expect(response).to be_successful
      expect(results["sold_issuances"]["issuances"]).to_not be_nil
      expect(results["sold_issuances"]["sources"][0]).to_not be_nil
      expect(results["sold_issuances"]["debt_types"][0]).to_not be_nil
      expect(results["sold_issuances"]["purposes"][0]).to_not be_nil
      expect(results["flat_issuances"]).to be_nil
      expect(Rails.cache.read("brea_riverside_issuer_data")).to_not be_empty
    end

    it "returns only :flat_issuances when :tabular_view is true" do
      VCR.use_cassette('issuers_debt_data_full_data') do
        get :bulk_issuer_data,
            issuers:      ["Brea", "Riverside"],
            debt_filters: {
              "issuer_group" => "Cities",
              "issuer_type"  => "City Government"
            },
            tabular_view: true,
            typeOfDebt: "sold"
      end

      results = JSON.parse(response.body)

      expect(response).to be_successful
      expect(results.length).to eq 1
      expect(results.keys).to eq ["flat_issuances"]
    end
  end

  context "Calculate Sums By Issuer" do
    let(:issuance_params) {
      {
        "exclusions"   => {
          "issuers"   => [],
          "sources"   => [],
          "debtTypes" => [],
          "purposes"  => []
        },
        "typeOfDebt"   => "proposed",
        "minDate"      => "",
        "maxDate"      => "",
        "debt_filters" => {
          "issuer_group" => "Cities",
          "issuer_type"  => "City Government"
        },
        "debt_type"    => 'proposed',
        "issuers"      => ["Los Angeles"]
      }
    }

    let(:response_hash) {
     {"new_money_sums"=>[["New Money", "Amount"], ["El Cerrito", 0], ["Compton", 10000000]], "principal_sums"=>[["Principal", "Amount"], ["El Cerrito", 0], ["Compton", 10000000]], "refund_sums"=>[["Refunding", "Amount"], ["El Cerrito", 0], ["Compton", 0]], "coi_average"=>[["Cost of Issuance", "Amount"], ["El Cerrito", 0], ["Compton", 0]], "flat_issuances"=>[{"cdiac_number_alias"=>"2015-1525", "issuer_alias"=>"Compton", "issuer_county_alias"=>"Los Angeles", "sold_status_alias"=>"PROPOSED", "federally_taxable_alias"=>" ", "sale_date_alias"=>2015, "private_placement_flag_alias"=>"YES", "debt_type_alias"=>"Tax and revenue anticipation note", "principal_amount_alias"=>"10000000", "source_of_repayment_alias"=>"General fund of issuing jurisdiction", "purpose_alias"=>"Cash Flow, Interim Financing", "refunding_amount_alias"=>"0", "tic_interest_rate_alias"=>" ", "nic_interest_rate_alias"=>" ", "interest_type_alias"=>" ", "other_interest_type_alias"=>" ", "project_name_alias"=>" ", "cab_flag_alias"=>"N/A", "final_maturity_date_alias"=>" ", "s_and_p_rating_alias"=>"Not Rated", "moody_rating_alias"=>"Not Rated", "fitch_rating_alias"=>"Not Rated", "other_rating_alias"=>"Not Rated", "financial_advisor_alias"=>"Comer Capital Group LLC", "guarantor_flag_alias"=>" ", "guarantor_alias"=>" ", "underwriter_alias"=>" ", "bond_counsel_alias"=>"Gonzalez Saggio & Harlan LLP", "co_bond_counsel_alias"=>" ", "purchaser_alias"=>" ", "borrower_counsel_alias"=>" ", "disclosure_counsel_alias"=>" ", "trustee_alias"=>" ", "issuer_group_alias"=>"Cities", "uw_expenses_alias"=>" ", "bond_counsel_fee_alias"=>" ", "disclosure_counsel_fee_alias"=>" ", "financial_advisor_fee_alias"=>" ", "rating_agency_fee_alias"=>" ", "credit_enhancement_fee_alias"=>" ", "trustee_fee_alias"=>" ", "other_issuance_expenses_alias"=>" ", "total_issuance_costs_alias"=>" ", "new_money_alias"=>"10000000", "issuer_type_alias"=>"City Government", "net_issue_discount_alias"=>" ", "first_optional_call_date_alias"=>" ", "sale_type_comp_neg_alias"=>"Neg", "placement_agent_alias"=>" ", "issue_cost_percent_of_principal_alias"=>" ", "uw_takedown_alias"=>" ", "uw_mngmt_fee_alias"=>" ", "uw_total_discount_spread_alias"=>" ", "placement_agent_fee_alias"=>" ", "co_bond_counsel_fee_alias"=>" ", "borrower_counsel_fee_alias"=>" ", "mkr_authority_alias"=>"NO", "local_obligation_alias"=>"NO", "mkr_cdiac_number_alias"=>" "}], "line_chart_data"=>{"new_money_sums"=>[["New Money", "Compton"], [2015, 10000000]], "principal_sums"=>[["Principal", "Compton"], [2015, 10000000]], "refund_sums"=>[["Refunding", "Compton"], [2015, 0]], "coi_sums"=>[["Cost of Issuance", "Compton"], [2015, 0]]}}
    }

    let(:null_line_chart_data_hash){
      {
        "new_money_sums" => [["New Money"]],
        "principal_sums" => [["Principal"]],
        "refund_sums"    => [["Refunding"]],
        "coi_sums"       => [["Cost of Issuance"]]
      }
    }

    it "calculates proposed values" do
      VCR.use_cassette('counties_with_proposed_values') do
        post :calculate_sums_by_issuer, issuance_params

        results = JSON.parse(response.body)

        expect(response).to be_successful
        expect(results["new_money_sums"].last.last).to_not be_nil
        expect(results["principal_sums"].last.last).to_not be_nil
        expect(results["refund_sums"].last.last).to_not be_nil
        expect(results["coi_average"].last.last).to_not be_nil
      end
    end

    it "calculates sold values and returns date array" do
      VCR.use_cassette('calculate_sold_values') do
        post :calculate_sums_by_issuer, convert_issuances_to_sold(issuance_params)

        expect(JSON.parse(response.body)["date_array"]).to eq(
          [1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995,
           1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006,
           2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015]
        )
      end
    end

    it "respects min and max date for sold issuances" do
      i_params = convert_issuances_to_sold(issuance_params)
      i_params['minDate'] = 2013

      VCR.use_cassette('respect_min_and_max_dates_for_sold_issuances') do
        post :calculate_sums_by_issuer, i_params

        data = JSON.parse(response.body)

        expect(data["line_chart_data"]["new_money_sums"].second[0]).to eq(2013)
        expect(data["line_chart_data"]["new_money_sums"].last[0]).to   eq(2015)
      end
    end

    it "ignores min and max date for proposed issuances" do
      issuance_params['minDate'] = '2013'
      issuance_params['maxDate'] = '2014'

      VCR.use_cassette('counties_with_proposed_values') do
        post :calculate_sums_by_issuer, issuance_params

        results = JSON.parse(response.body)

        expect(response).to be_successful
        expect(results["new_money_sums"].last.last).to_not be_nil
        expect(results["principal_sums"].last.last).to_not be_nil
        expect(results["refund_sums"].last.last).to_not be_nil
        expect(results["coi_average"].last.last).to_not be_nil
      end
    end

    it "returns the starter sums hash when typeOfDebt is unrecognized" do
      response_hash["new_money_sums"]  = [["New Money", "Amount"]]
      response_hash["principal_sums"]  = [["Principal", "Amount"]]
      response_hash["refund_sums"]     = [["Refunding", "Amount"]]
      response_hash["coi_average"]     = [["Cost of Issuance", "Amount"]]
      response_hash["flat_issuances"]  = []
      response_hash["line_chart_data"] = null_line_chart_data_hash

      issuance_params['typeOfDebt'] = 'foobar'

      VCR.use_cassette('returns_default_sums_when_typeOfDebt_is_unrecognized') do
        post :calculate_sums_by_issuer, issuance_params

        expect(JSON.parse(response.body)).to eq(response_hash)
      end
    end

    it "respects exclusions of issuances" do
      issuance_params['exclusions']['purposes'] = ['Interim Financing']

      VCR.use_cassette('respects_exclusions_of_issuances') do
        post :calculate_sums_by_issuer, issuance_params

        issuance_purposes = JSON.parse(response.body)["flat_issuances"].collect{ |iss| iss["purpose_alias"].downcase }
        matching_purposes = issuance_purposes.detect{ |purpose| purpose.include? 'interim financing' }

        expect(matching_purposes).to be_nil
      end
    end


    it "does not count 0 values in coi averages" do
      VCR.use_cassette('set_coi_to_zero') do
        post :calculate_sums_by_issuer, convert_issuances_to_sold(issuance_params)
      end

      expect(JSON.parse(response.body)["coi_average"]).to eq(
        [["Cost of Issuance", "Amount"], ["Los Angeles", 2.4351453488372097]]
      )
    end

    it "does not count null values in coi averages" do
      VCR.use_cassette('set_coi_to_nil') do
        post :calculate_sums_by_issuer, convert_issuances_to_sold(issuance_params)
      end

      expect(JSON.parse(response.body)["coi_average"]).to eq(
        [["Cost of Issuance", "Amount"], ["Los Angeles", 2.4351453488372097]]
      )
    end

    it "returns zero values from 'sold' when all issuances have been excluded to prevent chart errors" do
      i_params = convert_issuances_to_sold(issuance_params)

      i_params['exclusions']['purposes'] = ['INTERIM FINANCING']
      i_params['exclusions']['issuers']  = ['Los Angeles']

      VCR.use_cassette('all_issuances_excluded') do
        post :calculate_sums_by_issuer, i_params
      end

      expect(JSON.parse(response.body)["new_money_sums"]).to eq([["New Money", "Amount"]])
    end

    it "returns zero values from 'proposed' when all issuances have been excluded" do
      issuance_params['exclusions']['purposes'] = ['INTERIM FINANCING']
      issuance_params['exclusions']['issuers']  = ['Los Angeles']

      VCR.use_cassette('returns_0_values_when_all_excluded') do
        post :calculate_sums_by_issuer, issuance_params

        expect(JSON.parse(response.body)["new_money_sums"]).to eq([["New Money", "Amount"]])
      end
    end

    context "when there are no issuances in the params" do
      let(:post_hash){
        {
          "issuerValues" => {
            "Foothill Fire Protection District (SDALG)" => {
              "principal_sum" => 0,
              "refund_sum"    => 0,
              "new_money_sum" => 0
            },
            "San Miguel Consolidated Fire Protection District (SDALG)" => {
              "principal_sum" => 0,
              "refund_sum"    => 0,
              "new_money_sum" => 0
            }
          },
          "exclusions" => {
            "issuers"   => [],
            "sources"   => [],
            "debtTypes" => [],
            "purposes"  => []
          },
          "typeOfDebt" => "proposed",
          "minDate"    => "",
          "maxDate"    => "",
          "debt_filters" => {"issuer_group" => "Cities", "issuer_type" => "City Government"},
          "debt_type" => 'proposed',
          "issuers"=>["Foothill Fire Protection District (SDALG)", "San Miguel Consolidated Fire Protection District (SDALG)"]
        }
      }

      let(:response_hash) {
        {
          "new_money_sums"=> [
            ["New Money", "Amount"],
            ["Foothill Fire Protection District (SDALG)", 0],
            ["San Miguel Consolidated Fire Protection District (SDALG)", 0]
          ],
          "principal_sums"=> [
            ["Principal", "Amount"],
            ["Foothill Fire Protection District (SDALG)", 0],
            ["San Miguel Consolidated Fire Protection District (SDALG)", 0]
          ],
          "refund_sums"=> [
            ["Refunding", "Amount"],
            ["Foothill Fire Protection District (SDALG)", 0],
            ["San Miguel Consolidated Fire Protection District (SDALG)", 0]
          ],
          "coi_average" => [
            ["Cost of Issuance", "Amount"],
            ["Foothill Fire Protection District (SDALG)", 0],
            ["San Miguel Consolidated Fire Protection District (SDALG)", 0]
          ],
          "flat_issuances"  => [],
          "line_chart_data" => {
            "new_money_sums"=>[
              ["New Money", "Foothill Fire Protection District (SDALG)", "San Miguel Consolidated Fire Protection District (SDALG)"],
              ["", 0, 0]
            ],
            "principal_sums"=>[
              ["Principal", "Foothill Fire Protection District (SDALG)", "San Miguel Consolidated Fire Protection District (SDALG)"],
              ["", 0, 0]
            ],
            "refund_sums"=>[
              ["Refunding", "Foothill Fire Protection District (SDALG)", "San Miguel Consolidated Fire Protection District (SDALG)"],
              ["", 0, 0]
            ],
            "coi_sums"=>[
              ["Cost of Issuance", "Foothill Fire Protection District (SDALG)", "San Miguel Consolidated Fire Protection District (SDALG)"],
              ["", 0, 0]
            ]
          },
        }
      }

      it "returns zero values from 'proposed'" do
        VCR.use_cassette('zero_values_from_proposed') do
          post :calculate_sums_by_issuer, post_hash

          expect(JSON.parse(response.body)).to eq(response_hash)
        end
      end

      it "returns zero values from'sold' to prevent chart errors" do
        response_hash["date_array"] = []
        post_hash["typeOfDebt"] = "sold"

        VCR.use_cassette('zero_values_from_sold') do
          post :calculate_sums_by_issuer, post_hash
        end

        expect(JSON.parse(response.body)).to eq(response_hash)
      end
    end
  end
end
