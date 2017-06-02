class CalculationsService
  # Given a set of exclusions and issuances, munge the data into a format that
  #   the Angular front-end can work with
  # Only filter by date limitations if they are sent (for sold debt only)
  def calculations(sums_hash, exclusions, issuances_from_data, min_date, max_date)
    flat_issuances = []
    # Loop through issuances by issuer, summing values for non-excluded ones
    issuances_from_data.each do |issuerName, issuances|
      filtered_issuances = filter_issuances(exclusions, issuances, min_date, max_date)
      flat_issuances.push filtered_issuances

      refund_temp    = total_issuance_amounts(filtered_issuances, 'refunding_amount_alias')
      principal_temp = total_issuance_amounts(filtered_issuances, 'principal_amount_alias')

      sums_hash[:new_money_sums].push([issuerName, (principal_temp - refund_temp)])
      sums_hash[:principal_sums].push([issuerName, principal_temp])
      sums_hash[:refund_sums].push([issuerName, refund_temp])
      sums_hash[:coi_average].push([issuerName, average_coi(filtered_issuances)])
    end

    sums_hash[:flat_issuances] = flat_issuances.flatten
    sums_hash
  end

  def line_chart_data(issuances_from_data, exclusions, min_date, max_date)
    temp_hash  = { principal: {}, refund: {}, new_money: {}, coi: {} }
    date_array = []

    issuances_from_data.each do |issuer_name, issuances|
      filtered_issuances = filter_issuances(exclusions, issuances, min_date, max_date)

      filtered_issuances.each do |issuance|
        date_array, temp_hash = build_sold_data_for(issuance, date_array, temp_hash)
      end

      by_year = filtered_issuances.group_by { |i| i['sale_date_alias'] }

      by_year.each do |year, issuances_by_year|
        temp_hash[:coi][issuer_name] ||= {}
        temp_hash[:coi][issuer_name][year] ||= {}

        temp_hash[:coi][issuer_name][year] = average_coi(issuances_by_year)
      end
    end

    return build_zeroed_line_chart(issuances_from_data.keys, min_date) if temp_hash == { principal: {}, refund: {}, new_money: {}, coi: {} }

    build_chart_data(date_array.uniq, temp_hash)
  end

  private

  def build_zeroed_line_chart(issuer_names, min_date)
    starter_hash =  { 'new_money_sums' => [['New Money'], [min_date]],
                      'principal_sums' => [['Principal'], [min_date]],
                      'refund_sums' => [['Refunding'], [min_date]],
                      'coi_sums' => [['Cost of Issuance'], [min_date]] }

    issuer_names.each do |name|
      starter_hash.keys.each do |key|
        starter_hash[key].first.push(name)
        starter_hash[key].last.push(0)
      end
    end

    starter_hash
  end

  def build_sold_data_for(issuance, date_array, temp_hash)
    date_array.push(issuance['sale_date_alias'])

    { principal: 'principal_amount_alias',
      refund:    'refunding_amount_alias',
      new_money: 'new_money_alias' }.each do |k, v|
      temp_hash[k][issuance['issuer_alias']] ||= blank_hash

      # value = k == :coi ? issuance[v].to_f : issuance[v].to_i
      temp_hash[k][issuance['issuer_alias']][issuance['sale_date_alias']] += issuance[v].to_i
    end

    [date_array, temp_hash]
  end

  def blank_hash(default: 0)
    blank_slate = {}
    blank_slate.default = default
    blank_slate
  end

  def build_chart_data(date_array, temp_hash)
    # For each year in data array, check temp_hash for presence of that year
    #   for each issuer name & debt type. If sum for year doesn't exist,
    #   put 0 as value. Also, build first array of labels with issuer names
    date_array.sort.each do |year|
      temp_hash.each do |type, hashes|
        year_arr = [year]

        arr_of_issuer_names = chart_data_hash["#{type}_sums".to_sym]

        hashes.each do |name, values|
          arr_of_issuer_names[0].push(name) unless arr_of_issuer_names[0].include? name
          year_arr.push values[year] if values[year]
          year_arr.push 0 unless values[year]
        end

        arr_of_issuer_names.push(year_arr)
      end
    end

    chart_data_hash
  end

  def chart_data_hash
    @chart_data_hash ||= {
      new_money_sums: [%w(New\ Money)],
      principal_sums: [%w(Principal)],
      refund_sums:    [%w(Refunding)],
      coi_sums:       [%w(Cost\ of\ Issuance)]
    }
  end

  def average_coi(filtered_issuances)
    # Do not count any issuances that have a value of "0" or nil for the field
    filtered_issuances = filtered_issuances.reject do |iss|
      iss['issue_cost_percent_of_principal_alias'].to_f == 0.0
    end

    return 0 if filtered_issuances.length == 0

    total = filtered_issuances.collect { |iss| iss['issue_cost_percent_of_principal_alias'].to_f }.sum
    total / filtered_issuances.length
  end

  def filter_issuances(exclusions, issuances, min_date, max_date)
    filtered_issuances = issuances.reject { |iss| exclude_issuance?(exclusions, iss) }
    filtered_issuances = reject_older_than_max_date(filtered_issuances, max_date)
    filtered_issuances = reject_newer_than_min_date(filtered_issuances, min_date)
    filtered_issuances
  end

  def reject_older_than_max_date(issuances, date)
    reject_by_date(issuances, date, :>)
  end

  def reject_newer_than_min_date(issuances, date)
    reject_by_date(issuances, date, :<)
  end

  def reject_by_date(issuances, date, comparitor)
    return issuances if date.empty?

    issuances.reject { |iss| iss['sale_date_alias'].to_i.send(comparitor, date.to_i) }
  end

  # Extracted decision logic to determine if an issuance should be excluded
  def exclude_issuance?(exclusions, issuance)
    true if string_or_csv_included_by(exclusions[:sources], issuance[:source_of_repayment_alias]) ||
            string_or_csv_included_by(exclusions[:debtTypes], issuance[:debt_type_alias]) ||
            string_or_csv_included_by(exclusions[:purposes], issuance['purpose_alias'])
  end

  def string_or_csv_included_by(exclusion, attribute_list)
    exclusion.map(&:downcase).detect { |attribute| attribute_list.downcase.include? attribute }
  end

  def total_issuance_amounts(issuances, column)
    issuances.collect { |iss| iss[column].to_i }.sum
  end
end
