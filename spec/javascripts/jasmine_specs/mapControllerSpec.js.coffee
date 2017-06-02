#= require application
#= require jquery
#= require jquery_ujs
#= require d3
#= require bootstrap-sprockets
#= require mapbox.js
#= require jasmine-jquery
#= require angular
#= require angular-resource
#= require angular-sanitize
#= require angular-mocks

describe 'mapController', ->
  $scope = {}
  $rootScope = {}
  controller = {}
  $httpBackend = {}
  opacity = 0
  fillColor = 'blue'
  spyEvent = {}
  mouseover = null
  mouseout = null
  click = null

  layerEl =
    target:
      setStyle: (obj) ->
        opacity = obj.opacity
        fillColor = obj.fillColor
      feature:
        properties:
          NAME:
            'Test'
    on: (obj) ->
      mouseover = obj.mouseover
      mouseout = obj.mouseout
      click = obj.click

  beforeEach( ->
    module 'debtwatch'
    fixture.set('<div class="container"><div id="map"></div></div>')
  )

  beforeEach inject((_$controller_, $injector, $rootScope) ->
    $controller = _$controller_
    $scope = $injector.get('$rootScope').$new()
    $rootScope = $injector.get('$rootScope').$new()
    $httpBackend = $injector.get('$httpBackend')
    $httpBackend.when('GET', 'https://data.debtwatch.treasurer.ca.gov/api/assets/5F68F702-28B2-45D1-AF0A-D4C455A565F3?ca-counties-20m.geo.json')
      .respond([[{type: "FeatureCollection", features: [
        geometry:
          {
            "type": "Point",
            "coordinates": [
              -105.01621,
              39.57422
            ]
          }
        properties:
          CENSUSAREA: 594.583
          COUNTY: "005"
          GEO_ID: "0500000US06005"
          LSAD: "County"
          NAME: "Amador"
          STATE: "06"
      ]}],
      "foo", "bar", "baz"] );
    controller = $controller('mapController', $scope: $scope, map: map, $rootScope: $rootScope)
  )

  describe 'init', ->
    it 'sets appropriate variables', ->
      expect($scope.activeCounty).toEqual({})
      expect($scope.defaultLatLong).toEqual([37.2, -119.7])
      expect($scope.defaultZoom).toBe(6)
      expect($scope.clientDomain).toBe("https://data.debtwatch.treasurer.ca.gov")
      expect($rootScope.modalFixed).toBeFalsy()
      expect($rootScope.modalIsDisplayed).toBeFalsy()

    describe '$scope.createMap', ->
      it 'disables the scroll wheel', ->
        expect($scope.map.scrollWheel).toBeFalsy()

  describe '$scope.highlightFeature', ->
    it 'calls displaySummaryData if the modal is not fixed', ->
      $scope.countyHash = {Test: 'foo'}
      $scope.activeCounty = "bar"
      $rootScope.modalFixed = false
      $scope.highlightFeature(layerEl)
      expect($scope.activeCounty).toBe('foo')

  describe '$scope.resetHighlight', ->
    it 'sets opacity and fillColor to the appropriate values', ->
      $scope.resetHighlight(layerEl)
      expect(opacity).toBe(1)
      expect(fillColor).toBe('#4f80b2')

  describe '$scope.fixModal', ->
    it 'toggles the value of modalFixed', ->
      $scope.countyHash = {'Test': 'foo'}
      $scope.pos = {pageX: '4', pageY: '5'}
      $rootScope.modalFixed = true
      $scope.fixModal(layerEl)
      expect($rootScope.modalFixed).toBeTruthy()

  describe '$scope.displaySummaryData', ->
    it 'sets the active county variable to the appropriate value', ->
      $scope.activeCounty = "Wow"
      $scope.countyHash = {"Much test": "So county"}
      $scope.displaySummaryData("Much test")
      expect($scope.activeCounty).toBe("So county")

  describe '$scope.onEachFeature', ->
    it 'sets values for mouseover, mouseout, and click', ->
      $scope.highlightFeature = "blue"
      $scope.resetHighlight = "gray"
      $scope.fixModal = true
      $scope.onEachFeature('foo', layerEl)
      expect(mouseover).toBe('blue')
      expect(mouseout).toBe('gray')
      expect(click).toBeTruthy()

  describe '$scope.plotCounties', ->
    it 'sets countyGeo', ->
      $scope.clientDomain = 'https://data.debtwatch.treasurer.ca.gov'
      $scope.plotCounties()
      $httpBackend.flush()
      expect($scope.countyGeo[0][0].type).toEqual("FeatureCollection")
