app.controller 'mapController', ['$scope', '$http', '$rootScope', ($scope, $http, $rootScope) ->
  # Uses mapbox libraries to create map object used by view
  $scope.createMap = ->
    L.mapbox.accessToken = 'pk.eyJ1IjoibmlyZCIsImEiOiJkYTJhZjEzNjYwOWFhYjAxZTA2MmEwY2M3YTVjYjdmMSJ9.tkmsiYYqbIwwYELc-xskCw';

    $scope.map = L.mapbox.map('map','socrata.ie5c18he', {
      tileLayer: {
        detectRetina: true
      },
      zoomControl: false,
      touchZoom: true,
      keyboard: true
    }).setView($scope.defaultLatLong, $scope.defaultZoom)

    $scope.map.scrollWheelZoom.disable()
    $scope.map.dragging.disable()
    $scope.map.touchZoom.disable()
    $scope.map.doubleClickZoom.disable()

    return $scope.map

  # Change colour when user hovers over county if the modal is not fixed
  $scope.highlightFeature = (e) ->
    unless $rootScope.modalFixed
      $rootScope.modalIsDisplayed = true
      layer = e.target;

      layer.setStyle({
        opacity: 1,
        fillColor: '#C17600'
      })

      # When user hovers over county, display map flyout
      county = layer.feature.properties['NAME'];
      $scope.displaySummaryData(county);

  # Reset the color of the county when user is no longer hovering, if the modal is not fixed
  $scope.resetHighlight = (e) ->
    unless $rootScope.modalFixed
      $rootScope.modalIsDisplayed = false
      layer = e.target;

      layer.setStyle({
        opacity: 1,
        fillColor: '#4f80b2'
      });

  $scope.closeModalForReal = () ->
    $rootScope.modalFixed = false
    $rootScope.modalIsDisplayed = false
    if $scope.lastSelectedCounty
      $scope.lastSelectedCounty.setStyle({
        opacity: 1,
        fillColor: '#4f80b2'
      });

  # sets variable that will prevent modal from moving on mouseover
  # changes the color of last focused-on county back to non-focus color
  $scope.fixModal = (e) ->
    $rootScope.modalFixed = !$rootScope.modalFixed

    if !$rootScope.modalFixed
      if $scope.lastSelectedCounty
        $scope.lastSelectedCounty.setStyle({
          opacity: 1,
          fillColor: '#4f80b2'
        });
      $scope.highlightFeature(e)
      $scope.positionModal()
      $rootScope.modalFixed = true

    $scope.lastSelectedCounty = e.target

  $scope.onEachFeature = (feature, layer) ->
    layer.on({
      mouseover: $scope.highlightFeature,
      mouseout: $scope.resetHighlight,
      click: $scope.fixModal
    });

  $scope.plotCounties = ->
    # The geo json file to map out counties
    countyGeoJson = $scope.clientDomain + '/api/assets/5F68F702-28B2-45D1-AF0A-D4C455A565F3?ca-counties-20m.geo.json'

    # Retrieves geojson file to build layer with county map
    $http.get(countyGeoJson)
      .success((data, status, headers, config) ->
        $scope.countyGeo = data
        featureLayer = L.geoJson($scope.countyGeo, {
          style: {
            color: '#fff',
            weight: 2,
            opacity: 0.75,
            fillColor: '#4f80b2',
            fillOpacity: 1
          },
          onEachFeature: $scope.onEachFeature
        }).addTo($scope.map)
      ).error (data, status, headers, config) ->

  # This is the only cross browser way of getting a good substitute for e.originalEvent.layerX/layerY
  $scope.positionModal = ->
    position = $('#map').offset()
    docViewTop = $(window).scrollTop();

    # Determine if there is room above cursor for modal. If so, position it there.
    # If not, position it under cursor.
    # In either case, set a variable that will be applied as a class name,
    # used to build the little point under/over modal with CSS.
    if $scope.pos.pageY - docViewTop > 335
      y = 345
      $scope.modalClass = 'top'
    else
      y = -75
      $scope.modalClass = 'bottom'
    top = $scope.pos.pageY - (position.top) - y - $('.summary .county-name').height()

    left = $scope.pos.pageX - (position.left) - 45

    # ie11 is positioning the top closer than other browsers
    isIE11 = ! !navigator.userAgent.match(/Trident.*rv\:11\./)
    if isIE11
      top = top - 6

    $('#map-info-popup').css(
      position: 'absolute'
      left: left
      top: top).removeClass('top').removeClass('bottom').addClass($scope.modalClass)


  $scope.displaySummaryData = (location) ->
    # Grab the debt data values as per the indicated location
    $scope.activeCounty = $scope.countyHash[location]
    $scope.$apply()

  # When it receives a signal from the parent controller, it executes this code
  $scope.$on('closeModal', (event, data) ->
    unless angular.element(data.target).hasClass("overlay-link")
      $scope.closeModalForReal()
  )

  $scope.onMouseMove = ($event) ->
    $scope.pos = $event
    # Modal follows mouse position unless modal is fixed in place
    unless $rootScope.modalFixed
      $scope.positionModal()
      return

  setVariables = ->
    $scope.activeCounty = {}
    $scope.defaultLatLong = [37.2, -119.7]
    $scope.defaultZoom = 6
    $scope.clientDomain = "https://data.debtwatch.treasurer.ca.gov"
    $rootScope.modalFixed = false
    $rootScope.modalIsDisplayed = false

  init = ->
    setVariables()
    $scope.map = $scope.createMap()
    $scope.plotCounties()

  init()

]
