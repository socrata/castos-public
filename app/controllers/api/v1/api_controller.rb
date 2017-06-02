module Api
  module V1
    class ApiController < ActionController::Base
      # This method pulls in all information needed for the Landing Page to
      #   display properly. This includes static information and the map hover
      #   fly-out information.
      def landing_page_info
        data = {
          county_info:              fetch_county_map_info,
          landing_page_content:     fetch_landing_page_content,
          carousel_content:         fetch_carousel_content,
          issuer_group_wheel:       fetch_issuer_group_wheel_content,
          other_debt_issuance_data: fetch_other_debt_issuance_data
        }

        render json: check_data_for_errors(data)
      end

      # Used by the "Wheel" or "Donut" to filter issuer types by general group
      #   or category.
      def issuer_types_by_issuer_group
        data = {
          issuer_types: fetch_issuer_types_by_issuer_group(params[:issuer_group]).sort,
          static_data:  fetch_selection_page_data
        }

        render json: check_data_for_errors(data)
      end

      # Returns issues for a given issuer type
      def issuers_by_issuer_type
        data = {
          issuers:      fetch_issuers_by_issuer_type(params[:issuer_type], params[:issuer_group]).sort,
          static_data:  fetch_selection_page_data
        }

        render json: check_data_for_errors(data)
      end

      # This method pulls the data necessary for the issuer selection page to
      #   display the correct information based on its context. Context could be
      #     the county selected or the Socrata_Type selected.
      def issuers_by_county
        data = {
          issuers:      fetch_issuers_by_county(params[:county]).sort,
          static_data:  fetch_selection_page_data
        }

        render json: check_data_for_errors(data)
      end

      # This method pulls issuer debt data and chart data necessary for the
      #   initial view of the Comparison Tool
      def bulk_issuer_data
        sold_issuances, proposed_issuances = format_sold_and_proposed_issuances(
          params[:issuers],
          params[:debt_filters]
        )

        data = build_chart_array_data(
          sold_issuances,
          proposed_issuances
        )

        # If we are attempting to display the table view, we only need the data
        #   contained in data[:flat_issuances] which is populated in our call to
        #   #build_chart_array_data and the CalculationService object.
        if params[:tabular_view]
          data.select! { |k, _v| k == :flat_issuances }
          data[:flat_issuances].each do |column|
             if column['issuance_documents_alias']
               column['issuance_documents_alias_url'] = column['issuance_documents_alias']['url']
               column['issuance_documents_alias'] = column['issuance_documents_alias']['description']
             end
           end
        else
          data.reject! { |k, _v| k == :flat_issuances }
          data[:sold_issuances]     = sold_issuances
          data[:proposed_issuances] = proposed_issuances
        end
        render json: check_data_for_errors(data)
      end

      # Recalculate sums by issuer for display in the graphs
      def calculate_sums_by_issuer
        sold_issuances, proposed_issuances = format_sold_and_proposed_issuances(
          params[:issuers],
          params[:debt_filters]
        )

        data = build_chart_array_data(sold_issuances, proposed_issuances)
        data[:flat_issuances] = []

        render json: check_data_for_errors(data)
      end

      private

      def build_chart_array_data(sold_issuances, proposed_issuances)
        populate_issuances_from_data(
          params[:typeOfDebt],
          sold_issuances[:issuances],
          proposed_issuances[:issuances]
        )
        load_calculation_instance_variables
        filter_issuers_and_issuances_by_exclusions

        data = calculate_sums_by_type_of_debt(params[:typeOfDebt])

        # Build date array from unfiltered issuances, as it must include date of
        #   every issuance
        if params[:typeOfDebt] == 'sold'
          data[:date_array] = build_date_array_from(@issuances_from_data)
        end

        data
      end

      def format_sold_and_proposed_issuances(issuers, debt_filters)
        sold_issuances, proposed_issuances = fetch_bulk_issuer_data(issuers, debt_filters)

        [
          format_issuer_json_for(sold_issuances, issuers),
          format_issuer_json_for(proposed_issuances, issuers)
        ]
      end

      def populate_issuances_from_data(type_of_debt, sold_issuances, proposed_issuances)
        if type_of_debt == 'sold'
          @issuances_from_data = HashWithIndifferentAccess.new(sold_issuances)
        else
          @issuances_from_data = HashWithIndifferentAccess.new(proposed_issuances)
        end
      end

      # If issuers are being excluded, remove all their data from instance
      #   variables.This makes processing faster, and ensures that the issuer
      #   column doesn't appear in chart
      #
      # **NOTE:** This handles the exclusions by ISSUERS but not all possible
      #   kinds of exclusion
      def filter_issuers_and_issuances_by_exclusions
        @exclusions[:issuers].each do |excluded_issuer|
          @issuances_from_data.delete(excluded_issuer)
        end
      end

      def build_date_array_from issuances_from_data
        temp_date_array = []

        issuances_from_data.each do |_issuerName, issuances|
          temp_date_array.push(issuances.collect { |iss| iss['sale_date_alias'] })
        end

        temp_date_array = temp_date_array.flatten.uniq.sort
        temp_date_array.delete('')
        temp_date_array.delete(nil)
        temp_date_array
      end

      # Sets up a group of commonly used instance variables
      def load_calculation_instance_variables
        @max_date   = params[:maxDate] || ''
        @min_date   = params[:minDate] || ''
        @exclusions = params[:exclusions] || { issuers: [], sources: [], debtTypes: [], purposes: [] }
      end

      # Calculates the total amounts of new money, principal, and refunds for
      #   issuances of a given debt_type.
      def calculate_sums_by_type_of_debt(debt_type)
        sums_hash = {
          new_money_sums: [%w(New\ Money Amount)],
          principal_sums: [%w(Principal Amount)],
          refund_sums:    [%w(Refunding Amount)],
          coi_average:    [%w(Cost\ of\ Issuance Amount)],
          flat_issuances: []
        }

        case debt_type
        when 'proposed'
          CalculationsService.new.calculations(
            sums_hash,
            @exclusions,
            @issuances_from_data,
            '',
            ''
          )
        when 'sold'
          CalculationsService.new.calculations(
            sums_hash,
            @exclusions,
            @issuances_from_data,
            @min_date,
            @max_date
          )
        end

        sums_hash[:line_chart_data] = calculate_line_chart_data(params[:typeOfDebt])
        sums_hash
      end

      def calculate_line_chart_data(debt_type = 'sold')
        case debt_type
        when 'proposed'
          CalculationsService.new.line_chart_data(
            @issuances_from_data,
            @exclusions,
            '',
            ''
          )
        when 'sold'
          CalculationsService.new.line_chart_data(
            @issuances_from_data,
            @exclusions,
            @min_date,
            @max_date
          )
        else
          {
            'new_money_sums' => [['New Money']],
            'principal_sums' => [['Principal']],
            'refund_sums'    => [['Refunding']],
            'coi_sums'       => [['Cost of Issuance']]
          }
        end
      end

      # Perform a quick check for errors in generating data returns in a
      #   standard, repeatable way that allows the Angular front end to display
      #   some kind of messaging to the user
      def check_data_for_errors(data)
        if errors_hash[:errors].empty?
          data
        else
          { error: errors_hash[:errors].join(', ') }
        end
      end

      # A convenience method used to abstract the instance variable @errors_hash
      #   which is used for tracking errors as they occur in data munging
      def errors_hash
        @errors_hash ||= { errors: [] }
      end

      # Extracted logic for standardized formating of JSON returns for multiple
      #   data sets
      def format_issuer_json_for(issuances, issuers)
        {
          issuers:        issuers,
          issuances:      organize_by_issuer(issuances, issuers),
          sources:        extract_data_for_column(issuances, 'source_of_repayment_alias'),
          purposes:       extract_data_for_column(issuances, 'purpose_alias'),
          debt_types:     extract_data_for_column(issuances, 'debt_type_alias')
        }
      end

      # Builds a hash of issuances sorted by issuer
      #   { [issuer_name]: [{issuance, ...}]}
      def organize_by_issuer(issuances, issuers)
        by_issuer = {}

        issuers.each { |issuer| by_issuer[issuer] = [] }
        issuances.each { |issuance| by_issuer["#{issuance['issuer_alias']}"] << issuance }

        by_issuer
      end

      ##########################################################################
      ######## CACHING
      ##########################################################################

      # Abstracts calls to the CacheManager service so that we can centralize
      #   error-handling
      def fetch_data(cache_name:, method_name: nil, query_term: nil, ttl: 12.hours)
        method_name ||= CacheManager::CACHE_METHOD_NAMES[cache_name]

        data = CacheManager.new.cache(name: cache_name.to_s, ttl: ttl) do
          if query_term
            DebtWatch.new.send(method_name, query_term)
          else
            DebtWatch.new.send(method_name)
          end
        end

        if data.class == Hash && data[:error]
          errors_hash[:errors] << data[:error]
        end
        data
      end

      # Fetch data for building the county map and fly-outs
      def fetch_county_map_info
        fetch_data(cache_name: :county_map_info, ttl: 30.minutes)
      end

      # Fetch static data for building landing page
      def fetch_landing_page_content
        fetch_data(cache_name: :landing_page_content, ttl: 30.minutes)
      end

      # Fetch content for headlines carousel, currently located on the landing
      #   page below the navigation
      def fetch_carousel_content
        fetch_data(cache_name: :carousel_content, ttl: 30.minutes)
      end

      # Fetches data for building the "donut" or "wheel" on the landing page
      def fetch_issuer_group_wheel_content
        fetch_data(cache_name: :issuer_group_wheel, ttl: 30.minutes)
      end

      # Fetches data set of issuer types for a given issuer group
      def fetch_issuer_types_by_issuer_group(issuer_group)
        fetch_data(
          cache_name:  "#{issuer_group}_issuer_type_data".to_sym,
          method_name: :issuer_types_by_issuer_group,
          query_term:  issuer_group
        )
      end

      # Fetches data set of issuers for a given issuer type
      def fetch_issuers_by_issuer_type(issuer_type, issuer_group)
        fetch_data(
          cache_name:  "#{issuer_type}_#{issuer_group}_issuer_data".to_sym,
          method_name: :issuers_by_issuer_type,
          query_term:  { issuer_type: issuer_type, issuer_group: issuer_group }
        )
      end

      # Fetches a data set of issuers for a given county
      def fetch_issuers_by_county(county)
        fetch_data(
          cache_name:  "#{county}_issuer_data".to_sym,
          method_name: :issuers_by_county,
          query_term:  county
        )
      end

      # Fetches the Other Debt Issuance Data
      def fetch_other_debt_issuance_data
        fetch_data(
          cache_name:  'other_debt_issuance_data'.to_sym,
          method_name: :get_other_datasets
        )
      end

      # Fetches static data for building the issuers selection page
      def fetch_selection_page_data
        fetch_data(cache_name: :selection_page_data, ttl: 30.minutes)
      end

      # Fetches the bulk data of issuances for a set of issuers for use in the
      #   comparison tool itself, and does some basic data munging along the way
      def fetch_bulk_issuer_data(issuers, debt_filters)
        cache_name = "#{issuer_array_to_key(issuers)}_issuer_data"
        cache_name << 'tabular_view' if params[:tabular_view]

        issuances = fetch_data(
          cache_name:  cache_name.to_sym,
          method_name: :get_debt_for_issuers,
          query_term:  {
            issuers:      issuers,
            debt_filters: debt_filters,
            tabular_view: params[:tabular_view]
          }
        )

        issuances.each do |issuance|
          issuance['sale_date_alias'] = Date.parse(issuance['sale_date_alias']).strftime('%Y-%m-%d')
        end

        # return 2 arrays, partitioned into "sold" and "proposed" issuances
        issuances.partition { |issuance| issuance['sold_status_alias'] == 'SOLD' }
      end

      ##########################################################################
      ######## CALCULATIONS
      ##########################################################################

      # Primarily these are used for manipulating data responses from Socrata,
      #   in order to do summing and formating to provide to Angular the data
      #   it wants in the format it wants it in.
      #
      # TODO: It's likely these should be extracted to the CalculationsService

      def issuer_array_to_key(issuers)
        issuers.sort.join('_').downcase.gsub(%r{[()\/\[\]\s]}, '_')
      end

      def sum_array_columns(arr, column)
        arr.collect { |v| v[column].to_i }.sum
      end

      def extract_data_for_column(hash, column)
        Set.new(hash.collect { |i| i[column] })
      end
    end
  end
end
