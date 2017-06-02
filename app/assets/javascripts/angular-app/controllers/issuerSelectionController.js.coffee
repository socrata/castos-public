app.controller 'issuerSelectionController', ['$scope', '$rootScope', '$location', '$modal', '$filter',  '$sce', '$timeout', 'issuersByIssuerType', 'issuerTypeByGroupName', 'issuerSelectionByCountyService', 'bulkIssuerService', 'tabularDataService', 'calculationByIssuerService', 'flashService', 'googleChartApiPromise', ($scope, $rootScope, $location, $modal, $filter, $sce, $timeout, issuersByIssuerType, issuerTypeByGroupName, issuerSelectionByCountyService, bulkIssuerService, tabularDataService, calculationByIssuerService, flashService, googleChartApiPromise)->

  # methods for issuer_selection view --------------------------------------
  init = ->
    setVariables()

    # Get contents of URL query string
    params_from_url = $location.search()

    # Assign variables appropriately from URL query string
    $scope.typeOfData = params_from_url.type
    $scope.valueOfData = params_from_url.value

    # Hit proper API for requested data type
    if $scope.typeOfData == "type"
      $scope.issuerGroupName = $scope.valueOfData
      $scope.dataIdentifier = $scope.issuerGroupName
      # Prep object to be set by first dropdown on selection_form
      $scope.issuerType = {name: ""}
      getTypesByGroup() unless params_from_url.issuers

    if $scope.typeOfData == "county"
      $scope.showIssuersLoading = true
      $scope.county = $scope.valueOfData
      $scope.dataIdentifier = $scope.county + " County"
      getCountyIssuers() unless params_from_url.issuers

    # If URL query string has issuers in it already (is being used as deep link),
    # put issuers into appropriate variables and skip directly to submitting them to API
    if params_from_url.issuers
      # If only one issuer was selected, it's in URL as a string, not an array
      isArray = Array.isArray(params_from_url.issuers)
      if isArray
        $scope.selectedIssuerArray = params_from_url.issuers
        # Fill array because method checks that it contains at least one
        $scope.selectedIssuers = []
        for issuer in $scope.selectedIssuerArray
          $scope.selectedIssuers.push({id: issuer})
      else
        $scope.selectedIssuerArray = [params_from_url.issuers]
        $scope.selectedIssuers = [{id: params_from_url.issuers}]
      $scope.submitIssuers()

  setVariables = ->
    # Start off showing selection view, not charts
    $rootScope.selectionView = true
    $scope.comparisonView = false
    $scope.printableTableView = false

    # Date picker initial values
    $scope.maxDate = ""
    $scope.minDate = ""

    # Settings and empty models for dropdowns
    $scope.selectedIssuerType = []
    $scope.issuerTypeSettings = {selectionLimit: 1, showUncheckAll: false, enableSearch: true, scrollableHeight: '24rem', scrollable: true}
    $scope.issuerTypeButtonText = {buttonDefaultText: 'Select Issuer Type'}
    $scope.selectedIssuers = []
    $scope.issuersSettings = {selectionLimit: 5, enableSearch: true, scrollableHeight: '24rem', scrollable: true}
    $scope.issuersButtonText = {buttonDefaultText: 'Select Up to 5 Issuers'}

    # Exclude nothing from results at first, all checkboxes appear on page checked
    $scope.exclusions = {
      issuers: [],
      sources: [],
      debtTypes: [],
      purposes: []
    }

  # Send group name from URL params to Rails API to get issuer types to populate first dropdown
  getTypesByGroup = ->
    issuerTypeByGroupName.data({issuer_group: $scope.issuerGroupName})
      .$promise.then ((data) ->
        $scope.issuerTypes = []
        for type in data.issuer_types
          $scope.issuerTypes.push {id: type, label: type}

        $scope.explanationHeader = $sce.trustAsHtml(data.static_data[0].header_what_this_page_is_for_issuer_specific)
        $scope.pageExplanation = $sce.trustAsHtml(data.static_data[0].what_this_page_is_for_issuer_specific)
        $scope.expectationHeader = $sce.trustAsHtml(data.static_data[0].header_what_you_can_expect_on_next_page_issuer_specific)
        $scope.pageExpectation = $sce.trustAsHtml(data.static_data[0].what_you_can_expect_on_next_page_issuer_specific)
        return
      ), (data) ->
        return false

  # Triggered when first dropdown's value changes
  # Send selected type and group to Rails API to get issuers to populate second dropdown
  $scope.getTypeIssuers =->
    $scope.showIssuersLoading = true
    $scope.selectedIssuers = []
    issuersByIssuerType.data({issuer_type: $scope.selectedIssuerType.id, issuer_group: $scope.issuerGroupName})
      .$promise.then ((data) ->
        $scope.issuers = []
        for iss in data.issuers
          $scope.issuers.push {id: iss, label: iss}

        $scope.explanationHeader = $sce.trustAsHtml(data.static_data[0].header_what_this_page_is_for_issuer_specific)
        $scope.pageExplanation = $sce.trustAsHtml(data.static_data[0].what_this_page_is_for_issuer_specific)
        $scope.expectationHeader = $sce.trustAsHtml(data.static_data[0].header_what_you_can_expect_on_next_page_issuer_specific)
        $scope.pageExpectation = $sce.trustAsHtml(data.static_data[0].what_you_can_expect_on_next_page_issuer_specific)
        return
      ), (data) ->
        return false

  # Send county name from URL params to Rails API to get issuers to populate only dropdown
  getCountyIssuers = ->
    issuerSelectionByCountyService.data({county: $scope.county})
      .$promise.then ((data) ->
        $scope.issuers = []
        for iss in data.issuers
          $scope.issuers.push {id: iss, label: iss}

        $scope.explanationHeader = $sce.trustAsHtml(data.static_data[0].header_what_this_page_is_for_county_specific)
        $scope.pageExplanation = $sce.trustAsHtml(data.static_data[0].what_this_page_is_for_county_specific)
        $scope.expectationHeader = $sce.trustAsHtml(data.static_data[0].header_what_you_can_expect_on_next_page_county_specific)
        $scope.pageExpectation = $sce.trustAsHtml(data.static_data[0].what_you_can_expect_on_next_page_county_specific)
        return
      ), (data) ->
        return false

  # This is effectively the "init" method for the comparison_results view
  $scope.submitIssuers = ->
    $scope.showSubmitLoading = true

    # Respect business rule that data may only be shown for 5 issuers at a time
    if $scope.selectedIssuers.length > 5 || $scope.selectedIssuers.length < 1
      flashService.alert("Please select between 1 and 5 issuers")
      return false

    # Set initial page values
    $scope.chartType = 'bar'
    $scope.typeOfDebt = 'sold'
    $scope.chartsTab = true

    # Get issuances for selected issuers from API
    $scope.selectedIssuerArray = []
    for object in $scope.selectedIssuers
      $scope.selectedIssuerArray.push object.id

    # Add issuer array to URL
    $location.search('issuers', $scope.selectedIssuerArray)

    $scope.selectedDebtFilters = {}
    type = "issuer_" + $scope.typeOfData
    type = "issuer_group" if $scope.typeOfData == "type"
    $scope.selectedDebtFilters[type] = $scope.valueOfData
    $scope.selectedDebtFilters['issuer_type'] = $scope.selectedIssuerType.id if $scope.selectedIssuerType && $scope.selectedIssuerType.id

    bulkIssuerService.data({"issuers": $scope.selectedIssuerArray, debt_filters: $scope.selectedDebtFilters, typeOfDebt: $scope.typeOfDebt})
      .$promise.then ((data) ->
        $scope.masterData = data
        $scope.setVariablesByDebtType()
        $scope.chartSuccess(data)

        # Remove any lingering flash messages, hide selection, display charts
        flashService.clear()
        $rootScope.selectionView = false
        $scope.comparisonView = true

        return
      ), (data) ->
        flashService.alert("Unable to retrieve debt information at this time")
        return false

  # Methods for comparison_results view --------------------------------------------
  $scope.setVariablesByDebtType = ->
    if $scope.typeOfDebt == 'proposed'
      dataSource = $scope.masterData.proposed_issuances
    else if $scope.typeOfDebt == 'sold'
      dataSource = $scope.masterData.sold_issuances

    # Variables for filters, alphabetized
    $scope.issuersForFilters = dataSource.issuers.sort()
    $scope.sources = dataSource.sources.sort()
    $scope.purposes = dataSource.purposes.sort()
    $scope.debtTypes = dataSource.debt_types.sort()

    # These vars only used for sending back to API for calculations
    $scope.issuancesFromData = dataSource.issuances
    $scope.updateNeeded()

  # Add every item from specified filter list to the exclusion list
  $scope.unCheckAll = (filter) ->
    if filter == "all"
      $scope.exclusions = {
        issuers: angular.copy($scope.issuersForFilters),
        sources: angular.copy($scope.sources),
        debtTypes: angular.copy($scope.debtTypes),
        purposes: angular.copy($scope.purposes)
      }
    else if filter == "issuers"
      $scope.exclusions.issuers = angular.copy($scope.issuersForFilters)
    else
      $scope.exclusions[filter] = angular.copy($scope[filter])
    $scope.updateNeeded()

  # Remove every item from specified filter list the exclusion list
  $scope.checkAll = (filter) ->
    if filter == 'all'
      $scope.exclusions = {issuers: [], sources: [], debtTypes: [], purposes: []}
    else
      $scope.exclusions[filter] = []
    $scope.updateNeeded()

  $scope.resetCharts = (type) ->
    return false if $scope.greyCharts

    $scope.chartType = type

    # For sold data, line chart displays sums by year by issuer
    if $scope.chartType == 'line' && $scope.typeOfDebt == 'sold'
      # Draw the requested charts
      drawChart('chart1', $scope.principalSumsByYear, false)
      drawChart('chart2', $scope.refundSumsByYear, false)
      drawChart('chart3', $scope.newMoneySumsByYear, false)
      drawChart('chart4', $scope.coiSumsByYear, true)

    # For all other cases, chart displays sums by issuer only
    else if $scope.chartType == 'bar' || $scope.chartType == 'line'
      # Draw the requested charts
      googleChartApiPromise.then ->
        drawChart('chart1', $scope.principalSums, false)
        drawChart('chart2', $scope.refundSums, false)
        drawChart('chart3', $scope.newMoneySums, false)
        drawChart('chart4', $scope.coiSums, true)

  matchLength = (source, excl) ->
    source.length > 0 && excl.length == source.length

  resetInputNeeded = ->
    $scope.needIssuers = false
    $scope.needPurposes = false
    $scope.needSources = false
    $scope.needDebtTypes = false

  $scope.updateNeeded = ->
    exclusions = $scope.exclusions

    $scope.showRefresh = true
    $scope.greyCharts = true
    resetInputNeeded()

    if matchLength($scope.sources, exclusions.sources)
      $scope.needSources = true
      $scope.showRefresh = false
    if matchLength($scope.debtTypes, exclusions.debtTypes)
      $scope.needDebtTypes = true
      $scope.showRefresh = false
    if matchLength($scope.purposes, exclusions.purposes)
      $scope.needPurposes = true
      $scope.showRefresh = false
    if matchLength($scope.issuersForFilters, exclusions.issuers)
      $scope.needIssuers = true
      $scope.showRefresh = false

  $scope.calculateSums = ->
    if $scope.exclusions.issuers.length == $scope.issuersForFilters.length
      flashService.notice("No issuers selected")
      $scope.updateNeeded()
      return false

    chartLoading()

    calculationByIssuerService.data({exclusions: $scope.exclusions, typeOfDebt: $scope.typeOfDebt, minDate: $scope.minDate, maxDate: $scope.maxDate, issuers: $scope.selectedIssuerArray, debt_filters: $scope.selectedDebtFilters}).$promise.then ((data) ->

      $scope.showLoading = false

      if data.message
        chartFailure()
        flashService.alert(data.message)
      else
        $scope.chartSuccess(data)
      return
    ), (data) ->
      return false

  chartLoading=()->
    $scope.showRefresh = false
    $scope.showLoading = true

  chartFailure=()->
    $scope.greyCharts = true
    $scope.showRefresh = true
    return

  $scope.chartSuccess=(data)->
    $scope.greyCharts = false
    $scope.showRefresh = false
    # Data arrays for bar charts (sums by issuer)
    $scope.principalSums = data.principal_sums
    $scope.newMoneySums = data.new_money_sums
    $scope.refundSums = data.refund_sums
    $scope.coiSums = data.coi_average if data.coi_average
    # Data arrays for line charts (sums by issuer by year)
    $scope.principalSumsByYear = data.line_chart_data.principal_sums
    $scope.newMoneySumsByYear = data.line_chart_data.new_money_sums
    $scope.refundSumsByYear = data.line_chart_data.refund_sums
    $scope.coiSumsByYear = data.line_chart_data.coi_sums if data.line_chart_data.coi_sums
    # Dates of all issuances, to populate data dropdowns
    $scope.dateArray = data.date_array if data.date_array
    $scope.resetCharts($scope.chartType)

    getIssuancesForTable()

  getIssuancesForTable=()->
    # We make this call after everything else because it requires querying every
    # column in Socrata API, so is slow. Tabular data is not displayed on page load,
    # so it can be populated after rest of page is.
    tabularDataService.data({"issuers": $scope.selectedIssuerArray, debt_filters: $scope.selectedDebtFilters, exclusions: $scope.exclusions, typeOfDebt: $scope.typeOfDebt, minDate: $scope.minDate, maxDate: $scope.maxDate, tabular_view: true})

      .$promise.then ((data) ->
        # Flat array of issuances for tabular layout, headers for downloadable CSV
        $scope.issuancesHeaders = []
        $scope.issuancesArray = data.flat_issuances
        for key of data.flat_issuances[0]
          $scope.issuancesHeaders.push toTitleCase(key)
        return
      ), (data) ->
        flashService.alert("Unable to retrieve issuance information at this time")
        return false

  clearAllCharts =()->
    angular.element('#chart1').empty()
    angular.element('#chart2').empty()
    angular.element('#chart3').empty()
    angular.element('#chart4').empty()

  addAnnotationColumn =(dataArray)->
    for arr, i in dataArray when arr.length <= 2
        arr.push({ role: 'annotation' }) if i == 0
        arr.push(arr[1]) if i > 0
    return dataArray


  drawChart =(location, dataArray, isPercentage) ->
    dataArray = addAnnotationColumn(dataArray) if $scope.chartType =='bar'
    data = google.visualization.arrayToDataTable(dataArray)
    options =
      title: dataArray[0][0]
      legend: {postion: 'auto'}
      width: 800
      height: 500
      vAxis:
        format: 'currency'
      hAxis:
        format: ''
        slantedText:true
        slantedTextAngle:270
        gridlines:
          count: -1
        textPosition: 'out'

      colors: ["#007DAA", "#5C8000", "#C94D03", "#A14AA8", "#631B45", "#203680", "#346E00", "#8D3E7f"]

    if isPercentage
      formatter = new google.visualization.NumberFormat({negativeColor: 'red', suffix: '%'})
      options.vAxis.format = '#.#\'%\''
    else
      formatter = new google.visualization.NumberFormat({negativeColor: 'red', prefix: '$', fractionDigits: 0})

    # Apply the chosen formatter to all columns of data except the first
    columns = dataArray[0].length
    if columns > 1
      for n in [1..columns-1]
        formatter.format(data, n)

    if $scope.chartType =='bar'
      # Set the chart type to Column
      chart = new (google.visualization.ColumnChart)(document.getElementById(location))
      # Do not display a legend for this type of chart
      options.legend.position = 'none'
    else
      # Ensure there is a gridline for each year in the user's selected time span
      lowestYear = dataArray[1][0]
      lastIndex = parseInt(dataArray.length) - 1
      highestYear = dataArray[lastIndex][0]
      yearSpan = (parseInt(highestYear) - parseInt(lowestYear)) + 1
      options['hAxis']['gridlines']['count'] = yearSpan

      # Avoid known bug where labels are wacky if there is only one column by hiding label in that situation
      options['hAxis']['textPosition'] = 'none' if yearSpan == 1

      # Set the chart type to Line
      chart = new (google.visualization.LineChart)(document.getElementById(location))

    chart.draw data, options

    return

  # Display selection_form view with variables reset to initial values
  $scope.reset = ->
    $scope.selectedIssuers = []

    # Remove issuers array from URL query string
    $location.search('issuers', null)

    init()

    $scope.showSubmitLoading = false

    if $scope.typeOfData == "type"
      $scope.issuerType = {name: ""}
      $scope.issuers = null
      $scope.showIssuersLoading = false

  $scope.exportCSVData = (data) ->
    csvData = angular.copy(data)
    csvData.forEach (csvRow) ->
      if csvRow['issuance_documents_alias']
        csvRow['issuance_documents_alias'] = csvRow['issuance_documents_alias'] + ' (' + csvRow['issuance_documents_alias_url'] + ')'
        delete csvRow['issuance_documents_alias_url']
      return
    _.sortBy csvData, 'cdiac_number_alias'

  $scope.exportCSVDataHeader = (headers) ->
    csvDataHeader = angular.copy(headers)
    _.pull(csvDataHeader, 'Issuance Documents Url')
    csvDataHeader

  $scope.switchToPrintableTableView = ->
    $scope.printableTableView = true
    $scope.comparisonView = false
    $rootScope.selectionView = false

  $scope.switchToComparisonView = ->
    $scope.printableTableView = false
    $scope.comparisonView = true
    $rootScope.selectionView = false

  # Method for presentation, used in creating headers for downloadable CSV
  toTitleCase = (str) ->
    spacedStr = str.replace(/_alias/, "").replace(/_/g, " ")
    spacedStr.replace /\w\S*/g, (txt) ->
      txt[0].toUpperCase() + txt[1..txt.length - 1].toLowerCase()

  init()
]
