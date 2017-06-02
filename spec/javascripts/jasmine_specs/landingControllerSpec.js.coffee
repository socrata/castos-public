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

describe 'landingController', ->
  $scope = {}
  controller = {}
  $httpBackend = {}
  deferred = {}
  $q = {}
  mockLandingService = {}
  landingService = {}
  rootScope = {}

  beforeEach( ->
    module 'debtwatch'
  )

  beforeEach inject((_$controller_, $injector, $rootScope, $q) ->
    $controller = _$controller_
    $scope = $rootScope.$new()
    $httpBackend = $injector.get('$httpBackend')
    rootScope = $rootScope

    landingService =
      data: ->
        deferred = $q.defer()
        deferred.resolve({
          carousel_content: ['foo', 'bar', 'baz'],
          county_info: [{county: 'testCounty'}],
          issuer_group_wheel: [
            {
              Counties: {data_lens: 'foo', debt_amount: 'bar', socrata_group_description: 'buzz'}
            },
            {
              State: {data_lens: 'potato', debt_amount: 'banana', socrata_group_description: 'leek'}
            }
          ],
          landing_page_content: [
            { body_1: "body1", body_2: "body2", body_3: "body3", body_4: "body4", body_5: "body5", body_5: "body5", body_6: "body6", title_1: "title1", title_2: "title2", title_3: "title3", title_4: "title4", title_5: "title5"  }
          ],
          other_debt_issuance_data: [
            {url: "#1", name: "one"},
            {url: "#2", name: "two"}
          ]
        })

        $promise: deferred.promise

    controller = $controller('landingController', $scope: $scope, $rootScope: rootScope, landingService: landingService)
  )

  describe 'init', ->
    it 'assigns initial variables', ->
      rootScope.$digest()
      expect($scope.countyHash).toEqual({testCounty: { county: 'testCounty' }})
      expect($scope.firstSlide).toEqual('foo')
      expect($scope.laterSlides).toEqual(['bar', 'baz'])
      expect($scope.donutChartData).toEqual([{name: 'Counties', dataLens: 'foo', debtAmount: 'bar', description: 'buzz'}, {name: 'State', dataLens: 'potato', debtAmount: 'banana', description: 'leek'}])
      expect($scope.body1).toEqual("body1")
      expect($scope.body2).toEqual("body2")
      expect($scope.body3).toEqual("body3")
      expect($scope.body4).toEqual("body4")
      expect($scope.body5).toEqual("body5")
      expect($scope.body6).toEqual("body6")
      expect($scope.title1).toEqual("title1")
      expect($scope.title2).toEqual("title2")
      expect($scope.title3).toEqual("title3")
      expect($scope.title4).toEqual("title4")
      expect($scope.title5).toEqual("title5")
      expect($scope.otherIssuanceData).toEqual([{url: "#1", name: "one"},{url: "#2", name: "two"}])