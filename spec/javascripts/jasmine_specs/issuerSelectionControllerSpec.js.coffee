#= require application
#= require jquery
#= require jquery_ujs
#= require d3
#= require bootstrap-sprockets
#= require mapbox.js
#= require angular
#= require angular-resource
#= require angular-sanitize
#= require angular-mocks

describe 'issuerSelectionController, county', ->
  $scope = {}
  controller = {}
  $httpBackend = {}
  $rootScope = {}
  bulkIssuerService = {}
  issuersByIssuerType = {}
  googleChartApiPromise = {}

  apiData = {
    proposed_issuances:
      {
        issuers: ['propIss1', 'propIss2'],
        sources: ['src1', 'src2'],
        purposes: ['purp1', 'purp2'],
        debt_types: ['type2', 'type1'],
        issuances: [ {propIss1: [ {one: 'one'}, {two: 'two'} ]} ]
      }
    sold_issuances:
      {
        issuers: ['soldIss1', 'soldIss2'],
        sources: ['src1', 'src2'],
        purposes: ['purp1', 'purp2'],
        debt_types: ['type2', 'type1'],
        issuances: [ {soldIss1: [ {one: 'one'}, {two: 'two'} ]} ]
      }
    principal_sums: 'foo',
    new_money_sums: 'bar',
    refund_sums: 'baz',
    coi_average: 'ti',
    date_array: 'potato',
    line_chart_data: {
      principal_sums: 'fa',
      new_money_sums: 'so',
      refund_sums: 'la',
      coi_sums: 'do'}
    }

  tabularData = {
    flat_issuances: [
      {issuer: 'bananas'}
    ]
  }

  mockLocation = search: ->
      {}

  mockFlashService =
    alert: (alertMessage) ->
      $scope.flashServiceCalled = true
      $scope.alertMessage = alertMessage
    notice: (noticeMessage) ->
      $scope.flashServiceCalled = true
      $scope.noticeMessage = noticeMessage
    clear: ->
      $scope.flashServiceCalled = true
      return

  beforeEach( ->
    module 'debtwatch'
    module ($provide) ->
      $provide.value '$location', mockLocation
      return
    module ($provide) ->
      $provide.value 'flashService', mockFlashService
      return
  )

  beforeEach inject((_$controller_, $injector, _$location_, $q) ->
    $controller = _$controller_
    $scope = {}
    $rootScope = $injector.get('$rootScope')
    $location = _$location_

    bulkIssuerService =
      data: ->
        deferred = $q.defer()
        deferred.resolve(apiData)

        $promise: deferred.promise

    tabularDataService =
      data: ->
        deferred = $q.defer()
        deferred.resolve(tabularData)

        $promise: deferred.promise

    issuersByIssuerType =
      data: (obj) ->
        deferred = $q.defer()
        deferred.resolve(
          {
            issuers: ['foo'],
            static_data: [{what_this_page_is_for_issuer_specific: 'foo', what_you_can_expect_on_next_page_issuer_specific: 'bar'}]
          }
        )
        $promise: deferred.promise

    googleChartApiPromise =
      then: ->
        "foo"

    mockCalculationByIssuerService =
      data: (obj) ->
        deferred = $q.defer()
        if obj.issuancesFromData
          deferred.resolve({message: 'this is a message'})
        else
          deferred.resolve({
            principal_sums: 'foo',
            new_money_sums: 'bar',
            refund_sums: 'baz',
            coi_average: 'ti',
            date_array: 'potato',
            line_chart_data: {
              principal_sums: 'fa',
              new_money_sums: 'so',
              refund_sums: 'la',
              coi_sums: 'do'}
          })

        $promise: deferred.promise

    $httpBackend = $injector.get('$httpBackend')
    $httpBackend.when('GET', '/api/v1/issuers_by_county/Unit%20Testing.json')
      .respond('foo')
    $httpBackend.when('POST', '/api/v1/calculate_sums_by_issuer.json')
      .respond('foo')

    controller = $controller('issuerSelectionController', $scope: $scope, $rootScope: $rootScope, $location: $location, bulkIssuerService: bulkIssuerService, tabularDataService: tabularDataService, issuersByIssuerType: issuersByIssuerType, calculationByIssuerService: mockCalculationByIssuerService, googleChartApiPromise: googleChartApiPromise)
  )

  describe 'init', ->
    mockLocation = search: ->
      {type: 'county', value:'Unit Testing'}

    it 'initializes variables', ->
      expect($rootScope.selectionView).toBeTruthy()
      expect($scope.comparisonView).toBeFalsy()
      expect($scope.selectedIssuers).toEqual([])

    describe 'county', ->
      it 'initializes variables', ->
        expect($scope.typeOfData).toEqual('county')
        expect($scope.county).toEqual('Unit Testing')
        expect($scope.dataIdentifier).toEqual('Unit Testing County')

  describe '$scope.submitIssuers', ->
    it 'throws an error if more than 5 issuers are selected', ->
      $scope.flashServiceCalled = false
      $scope.selectedIssuers = ['foo', 'bar', 'baz', 'potato', 'banana', 'couch', 'table']
      $scope.submitIssuers()
      expect($scope.flashServiceCalled).toBeTruthy()
      expect($scope.alertMessage).toEqual("Please select between 1 and 5 issuers")

    it 'flashes an error if no issuers are selected', ->
      $scope.flashServiceCalled = false
      $scope.selectedIssuers = []
      $scope.submitIssuers()
      expect($scope.flashServiceCalled).toBeTruthy()
      expect($scope.alertMessage).toEqual('Please select between 1 and 5 issuers')

    it 'sets initial page values', ->
      $scope.chartType = 'foo'
      $scope.typeOfDebt = 'none'
      $scope.selectedIssuers = ['foo']
      $scope.submitIssuers()

      expect($scope.chartType).toBe('bar')
      expect($scope.typeOfDebt).toBe('sold')

    it 'calls the bulkIssuerService promise', ->
      $scope.selectedIssuers = ['foo']
      $scope.submitIssuers()
      $rootScope.$digest()

      expect($scope.masterData).toEqual(apiData)

    it 'sets appropriate variables', ->
      $scope.selectedIssuers = ['foo']
      $rootScope.selectionView = true
      $scope.comparisonView = false
      $scope.submitIssuers()
      $rootScope.$digest()

      expect($rootScope.selectionView).toBeFalsy()
      expect($scope.comparisonView).toBeTruthy()

  describe 'setVariablesByDebtType', ->
    it 'sets variables properly when debt type is "proposed"', ->
      $scope.typeOfDebt = 'proposed'
      $scope.masterData = apiData
      $scope.setVariablesByDebtType()

      expect($scope.issuersForFilters).toEqual(['propIss1', 'propIss2'])
      expect($scope.sources).toEqual(['src1', 'src2'])
      expect($scope.purposes).toEqual(['purp1', 'purp2'])
      # alphabetizes filters
      expect($scope.debtTypes).toEqual(['type1', 'type2'])
      # check a property of the object, as comparing objects for equality doesn't work
      expect($scope.issuancesFromData[0].propIss1[0].one).toEqual('one')

    it 'sets variables properly when debt type is "sold"', ->
      $scope.typeOfDebt = 'sold'
      $scope.masterData = apiData
      $scope.setVariablesByDebtType()

      expect($scope.issuersForFilters).toEqual(['soldIss1', 'soldIss2'])
      expect($scope.sources).toEqual(['src1', 'src2'])
      expect($scope.purposes).toEqual(['purp1', 'purp2'])
      # alphabetizes filters
      expect($scope.debtTypes).toEqual(['type1', 'type2'])
      # check a property of the object, as comparing objects for equality doesn't work
      expect($scope.issuancesFromData[0].soldIss1[0].one).toEqual('one')

  describe 'check all', ->
    it 'empties exclusions hash', ->
      $scope.exclusions = { issuers: [], sources: [], debtTypes: [], purposes: [] }
      $scope.issuersForFilters = ['foo']
      $scope.sources = ['bar']
      $scope.debtTypes = ['potato']
      $scope.purposes = ['banana']
      $scope.checkAll('all')
      expect($scope.exclusions).toEqual({ issuers: [], sources: [], debtTypes: [], purposes: [] })

  describe 'uncheck all', ->
    it 'fills exclusions hash', ->
      $scope.exclusions = { issuers: [], sources: [], debtTypes: [], purposes: [] }
      $scope.issuersForFilters = ['foo']
      $scope.sources = ['bar']
      $scope.debtTypes = ['potato']
      $scope.purposes = ['banana']
      $scope.unCheckAll('all')

      expect($scope.exclusions.issuers).toEqual(['foo'])
      expect($scope.exclusions.sources).toEqual(['bar'])
      expect($scope.exclusions.debtTypes).toEqual(['potato'])
      expect($scope.exclusions.purposes).toEqual(['banana'])

  describe '$scope.resetCharts', ->

    it 'sets variable to passed chart type', ->
      $scope.chartType = 'foo'
      $scope.resetCharts('bar')
      $rootScope.$digest()

      expect($scope.chartType).toBe('bar')

    it 'does not draw charts or reset type if $scope.greyCharts is true', ->
      $scope.chartType = 'bar'
      $scope.greyCharts = true
      $scope.principalSums = 'foo'
      $scope.refundSums = 'bar'
      $scope.newMoneySums = 'baz'
      spyOn(googleChartApiPromise, 'then')
      $scope.resetCharts('line')
      $rootScope.$digest()

      expect($scope.chartType).toBe('bar')
      expect(googleChartApiPromise.then).not.toHaveBeenCalled()

    it 'does draw charts', ->
      $scope.chartType = 'bar'
      $scope.greyCharts = false
      $scope.principalSums = 'foo'
      $scope.refundSums = 'bar'
      $scope.newMoneySums = 'baz'
      spyOn(googleChartApiPromise, 'then')
      $scope.resetCharts('line')
      $rootScope.$digest()

      expect($scope.chartType).toBe('line')
      expect(googleChartApiPromise.then).toHaveBeenCalled()

  describe '$scope.calculateSums', ->
    it 'calls the flash service & returns false if no issuers are selected', ->
      $scope.issuersForFilters = ['foo']
      $scope.sources = ['bar']
      $scope.debtTypes = ['potato']
      $scope.purposes = ['banana']
      $scope.flashServiceCalled = false
      $scope.exclusions.issuers = ['foo']
      $scope.calculateSums()
      $rootScope.$digest()

      expect($scope.flashServiceCalled).toBeTruthy()

    it 'sets appropriate variables', ->
      $scope.issuersForFilters = ['foo']
      $scope.sources = ['bar']
      $scope.debtTypes = ['potato']
      $scope.purposes = ['banana']
      $scope.calculateSums()
      $rootScope.$digest()

      expect($scope.principalSums).toBe('foo')
      expect($scope.newMoneySums).toBe('bar')
      expect($scope.refundSums).toBe('baz')
      expect($scope.coiSums).toBe('ti')
      expect($scope.principalSumsByYear).toBe('fa')
      expect($scope.newMoneySumsByYear).toBe('so')
      expect($scope.refundSumsByYear).toBe('la')
      expect($scope.coiSumsByYear).toBe('do')

    it 'chartSuccess calls tabularDataService to get tabular data after everything else is done', ->
      $scope.issuersForFilters = ['foo']
      $scope.sources = ['bar']
      $scope.debtTypes = ['potato']
      $scope.purposes = ['banana']
      $scope.calculateSums()
      $rootScope.$digest()

      expect($scope.issuancesArray).toEqual([{issuer: 'bananas'}])
      expect($scope.greyCharts).toBeFalsy()
      expect($scope.showRefresh).toBeFalsy()

  describe '$scope.getTypeIssuers', ->
    it 'sets appropriate variables', ->
      $scope.issuerType = {name: 'bar', id: 1}
      $scope.getTypeIssuers()
      $rootScope.$digest()

      expect($scope.pageExplanation).not.toBe(null)
      expect($scope.pageExpectation).not.toBe(null)
      expect($scope.issuers).toEqual([{ id: 'foo', label: 'foo' }])

  describe '$scope.reset for county', ->
    mockLocation = search: ->
      {type: 'county', value:'Unit Testing'}

    it 'resets variables appropriately for any typeOfData', ->
      $scope.selectedIssuers = ['foo']
      $scope.showSubmitLoading = true
      $scope.reset()

      expect($scope.selectedIssuers).toEqual([])
      expect($scope.showSubmitLoading).toBeFalsy()

  createData = ->
    $scope.exclusions = {sources: [], issuers: [], debtTypes: [], purposes: []}
    $scope.issuancesFromData =
      {
        TestingAuthorities: [
          {
            issuer: "TestingAuthorities",
            source_of_repayment: "Testing Authority Inc.",
            debt_type: "Testy",
            purpose: "New Shoes",
            principal_amount: "10",
            refunding_amount: "5",
            new_money_sum: "5",
            sold_status: "PROPOSED"
          },
          {
            issuer: "TestingAuthorities",
            source_of_repayment: "Testing Authority Inc.",
            debt_type: "Testy",
            purpose: "Fabulous New Shoes",
            principal_amount: "100",
            refunding_amount: "50",
            new_money_sum: "50",
            sold_status: "PROPOSED"
          } ],
        Foobar: [
          {
            issuer: "Foobar",
            source_of_repayment: "Barbaz",
            debt_type: "Bazfoo",
            purpose: "Potato",
            principal_amount: "15",
            refunding_amount: "3",
            new_money_sum: "12",
            sold_status: "PROPOSED"
          },
          {
            issuer: "Foobar",
            source_of_repayment: "Barbaz",
            debt_type: "Testy",
            purpose: "Fabulous New Shoes",
            principal_amount: "75",
            refunding_amount: "20",
            new_money_sum: "55",
            sold_status: "PROPOSED"
          } ]
      }

describe 'issuerSelectionController, type', ->
  $scope = {}
  controller = {}
  $httpBackend = {}
  $rootScope = {}

  mockLocation = search: ->
      {type: 'type', value:'Unit Tests'}

  beforeEach( ->
    module 'debtwatch'
    module ($provide) ->
      $provide.value '$location', mockLocation
      return
  )

  beforeEach inject((_$controller_, $injector, $q) ->
    $controller = _$controller_
    $scope = {}
    $rootScope = $injector.get('$rootScope')

    controller = $controller('issuerSelectionController', $scope: $scope)
  )

  describe 'init', ->
    it 'initializes variables', ->
      expect($rootScope.selectionView).toBeTruthy()
      expect($scope.comparisonView).toBeFalsy()
      expect($scope.selectedIssuers).toEqual([])

    describe 'type', ->
      it 'initializes variables', ->
        expect($scope.typeOfData).toEqual('type')
        expect($scope.issuerGroupName).toEqual('Unit Tests')
        expect($scope.dataIdentifier).toEqual('Unit Tests')
        expect($scope.issuerType).toEqual({name: ""})

  describe '$scope.reset for type', ->
    it 'resets variables appropriately for "type" comparison', ->
      $scope.selectedIssuers = ['foo']
      $scope.showSubmitLoading = true

      $scope.issuerType = {name: 'bar', id: 1}
      $scope.showIssuersLoading = true
      $scope.issuers = []
      $scope.reset()

      expect($scope.selectedIssuers).toEqual([])
      expect($scope.showSubmitLoading).toBeFalsy()
      expect($scope.issuerType).toEqual({name: ""})
      expect($scope.showIssuersLoading).toBeFalsy()
      expect($scope.issuers).toEqual(null)
