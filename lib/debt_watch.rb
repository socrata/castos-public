require 'set'

# search for things by issuer, counties, Socrata type, issuer type

class DebtWatch
  # Whitelist of column names to fetch data for when querying for issuances
  COLUMN_NAME_FILTER = [
    'Issuer', 'Issuer Group', 'Issuer Type', 'Issuer County', 'Sold Status',
    'Sale Date', 'Debt Type', 'Source of Repayment', 'Purpose',
    'Principal Amount', 'Refunding Amount', 'New Money', 'CDIAC Number', 'Issuance Documents',
    'CAB Flag', 'S and P Rating', 'Moody Rating', 'Guarantor', 'Guarantor Flag',
    'Underwriter', 'Lender', 'Trustee', 'Bond Counsel', 'Financial Advisor',
    'Sale Type (Comp Neg)', 'Private Placement Flag', 'Total Issuance Costs',
    'Issue Cost percent of Principal', 'Federally Taxable', 'TIC Interest Rate',
    'NIC Interest Rate', 'Interest Type', 'Other Interest Type', 'Project Name',
    'Final Maturity Date', 'Fitch Rating', 'Other Rating', 'Purchaser',
    'Borrower Counsel', 'Disclosure Counsel', 'UW Expenses', 'Bond Counsel Fee',
    'Disclosure Counsel Fee', 'Financial Advisor Fee', 'Rating Agency Fee',
    'Credit Enhancement Fee', 'Trustee Fee', 'Other Issuance Expenses', 'Net Issue Discount',
    'First Optional Call Date', 'Placement Agent', 'UW Takedown', 'Placement Agent Fee',
    'Borrower Counsel Fee', 'Co-Bond Counsel', 'Co-Bond Counsel Fee', 'UW Total Discount/Spread',
    'MKR Authority', 'Local Obligation', 'MKR CDIAC Number', 'UW Mngmt Fee'
  ]

  def initialize
    @soda_client              = SODA::Client.new(client_options)
    @current_column_names     = current_column_names
    @column_name_hash         = column_name_hash
    @column_name_hash_length  = @column_name_hash.length
    @limited_column_name_hash = filtered_column_names

    @default_column_set = @column_name_hash.dup
    @default_column_set.each { |k, _v| @default_column_set[k] = ' ' }

    @default_limited_column_set = @limited_column_name_hash.dup
    @default_limited_column_set.each do |k, _v|
      @default_limited_column_set[k] = ' '
    end
  end

  # Fetch information for county map
  def map_info(limit: 58, select: '')
    @soda_client.get(
      Figaro.env.county_map_dataset,
      '$limit'  => limit,
      '$select' => select
    )
  end

  # Fetch static content for building the landing page
  def static_landing_page_content
    @soda_client.get(
      Figaro.env.landing_page_dataset
    )
  end

  # Fetch static content for the selection page
  def selection_page_data
    @soda_client.get(
      Figaro.env.select_page_dataset
    )
  end

  # Fetch data for building the headlines carousel
  def carousel_content
    @soda_client.get(
      Figaro.env.carousel_dataset
    )
  end

  # Fetch issuer groups for building the "wheel" or "donut"
  def get_issuer_groups
    issuer_group_data = @soda_client.get(
      Figaro.env.wheel_reference)

    results = []
    issuer_group_data.each do |issuer_group|
      results << {
        issuer_group['socrata_group'] =>
          {
            'debt_amount'               => issuer_group['debt_issued_in_past_12_months'],
            'data_lens'                 => issuer_group['datalens'],
            'socrata_group_description' => issuer_group['socrata_group_description']
          }
      } unless issuer_group.blank?
    end
    results
  end

  # Fetch issuer types for a given issuer_group
  def issuer_types_by_issuer_group(issuer_group)
    response = search_by_column(
      column: @column_name_hash['issuer_group_alias'],
      value:  issuer_group,
      select: @column_name_hash['issuer_type_alias']
    )

    Set.new(response.collect(&:values).flatten)
  end

  # Fetch issuers for a given issuer type
  def issuers_by_issuer_type(query_terms)
    response = search_by_columns(
      column_hash: { 'issuer_type' => query_terms[:issuer_type],
                     'issuer_group' => query_terms[:issuer_group] },
      select: @column_name_hash['issuer_alias']
    )

    Set.new(response.collect(&:values).flatten)
  end

  # Returns a Set of Issuer names by county
  def issuers_by_county(county_name)
    response = search_by_column(
      column: @column_name_hash['issuer_county_alias'],
      value:  county_name,
      select: @column_name_hash['issuer_alias']
    )

    Set.new(response.collect(&:values).flatten)
  end

  # Returns the bulk data for the Other Debt Issuance Data
  def get_other_datasets
    @soda_client.get(
      Figaro.env.other_issuance_data
    )
  end

  # Search for issuances by a column with a value.
  def search_by_column(column:, value:, select: '', limit: 50_000, populate_null_columns: false)
    data = @soda_client.get(
      Figaro.env.issuer_dataset,
      '$limit'  => limit,
      '$select' => select,
      '$where'  => "#{column} = '#{value}'"
    )

    return create_missing_columns(data) if populate_null_columns

    data
  end

  # Variant of #search_by_column to allow searching on multiple columns when
  #   seeking data at the intersection.
  def search_by_columns(column_hash:, select: '', limit: 50_000, populate_null_columns: false)
    where_string = column_hash.map do |k, v|
      column_name = "#{k}_alias"
      "#{@column_name_hash[column_name]} = '#{v}'"
    end.join(' AND ')

    data = @soda_client.get(
      Figaro.env.issuer_dataset,
      '$limit'  => limit,
      '$select' => select,
      '$where'  => where_string
    )
    return create_missing_columns(data) if populate_null_columns

    data
  end

  # Takes an array of issuers by issuer name.
  # Searches the dataset for all debt associated with that issuer.
  # Returns a hash of issuers organized by issuer.
  def get_debt_for_issuers(issuers:, debt_filters:, tabular_view: false)
    where_query  = compose_query(issuers, debt_filters)
    select_query = tabular_view ? select_all_columns : select_limited_columns
    column_set   = tabular_view ? @default_column_set : @default_limited_column_set

    data = @soda_client.get(
      Figaro.env.issuer_dataset,
      '$where'  => where_query,
      '$select' => select_query,
      '$limit'  => 50_000
    )

    create_missing_columns(data, column_set.dup)
  end

  private

  def client_options
    options = {
      domain:    ENV['debtwatch_domain'],
      app_token: ENV['debtwatch_app_token'],
      username:  ENV['debtwatch_username'],
      password:  ENV['debtwatch_password']
    }

    options[:ignore_ssl] = true unless Rails.env.production?

    options
  end

  def create_missing_columns(data, column_set = @default_column_set.dup)
    new_data_set = []

    data.each do |record|
      new_data_set << column_set.merge(record)
    end

    new_data_set
  end

  def filtered_column_names
    @column_name_hash.select do |k, _v|
      %w(cdiac_number_alias issuer_alias issuer_county_alias sold_status_alias sale_date_alias debt_type_alias principal_amount_alias purpose_alias refunding_amount_alias total_issuance_costs_alias new_money_alias issuer_type_alias net_issue_discount_alias issuer_group_alias source_of_repayment_alias issue_cost_percent_of_principal_alias).include? k
    end
  end

  # Used as part of the "mappable" column names, fetches the current list of
  #   column names along with their original values
  def current_column_names
    @soda_client.get(
      Figaro.env.column_map_dataset
    )
  end

  # Returns a hash of permanent and current column names
  def column_name_hash
    name_hash = {}

    @current_column_names.each do |column|
      if column_conditions(column)
        name_hash[format_column_name(column)] = column['issuer_dataset_match'].downcase.gsub(%r{[-\/\s]}, '_').delete('()')
      end
    end

    name_hash
  end

  # Append '_alias' to column names to avoid SoQL errors
  def format_column_name(column)
    column['permanent_castos'].downcase.gsub(%r{[-\/\s]}, '_').delete('()') + '_alias'
  end

  def column_conditions(column)
    COLUMN_NAME_FILTER.include?(column['permanent_castos']) && !column['permanent_castos'].nil?
  end

  def select_all_columns
    build_select_query(@column_name_hash)
  end

  def select_limited_columns
    build_select_query(@limited_column_name_hash)
  end

  def build_select_query(column_set)
    column_set.each_with_object([]) do |(permanent, current), obj|
      obj << "#{current} as #{permanent}"
    end.join(', ')
  end

  def compose_query(issuers, debt_filters)
    query = issuers.map { |issuer| "#{@column_name_hash['issuer_alias']} = '#{escape_quotes(issuer)}'" }.join(' OR ')

    filter = debt_filters.map do |k, v|
      column_name = "#{k}_alias"
      "#{@column_name_hash[column_name]} = '#{escape_quotes(v)}'"
    end.join(' AND ')

    "(#{filter}) AND (#{query})"
  end

  def escape_quotes(to_escape)
    to_escape.gsub("'", "''")
  end
end
