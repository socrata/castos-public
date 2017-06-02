app.controller 'landingController', ['$scope', '$sce', '$rootScope', 'landingService', ($scope, $sce, $rootScope, landingService)->

  init = ->
    $rootScope.modalFixed = false
    $rootScope.modalIsDisplayed = false
    landingService.data()
      .$promise.then ((data) ->
        $scope.countyHash = {}
        carousel = data.carousel_content
        if carousel.length > 2
          $scope.firstSlide = carousel[0]
          $scope.laterSlides = carousel.slice(1)
        $scope.donutChartData = []
        $scope.otherIssuanceData = data.other_debt_issuance_data

        for group in data.issuer_group_wheel
          obj = {}

          for key, value of group
            obj["name"] = key
            obj["dataLens"] = value.data_lens
            obj["debtAmount"] = value.debt_amount
            obj["description"] = value.socrata_group_description
          $scope.donutChartData.push(obj)

        drawDonutChart()

        $scope.body1 = data.landing_page_content[0].body_1
        $scope.body2 = data.landing_page_content[0].body_2
        $scope.body3 = data.landing_page_content[0].body_3
        $scope.body4 = data.landing_page_content[0].body_4
        $scope.body5 = data.landing_page_content[0].body_5
        $scope.body6 = data.landing_page_content[0].body_6
        $scope.title1 = data.landing_page_content[0].title_1
        $scope.title2 = data.landing_page_content[0].title_2
        $scope.title3 = data.landing_page_content[0].title_3
        $scope.title4 = data.landing_page_content[0].title_4
        $scope.title5 = data.landing_page_content[0].title_5

        for obj in data.county_info
          $scope.countyHash[obj.county] = obj
        return
      ), (data) ->
        return false

  $scope.hideMapModal = () ->
    if !$rootScope.modalFixed
      $rootScope.modalIsDisplayed = false

  drawDonutChart = ->
    $scope.centerData = ""
    # Define size & radius of donut pie chart
    width = 500
    height = 500
    radius = Math.min(width, height) / 2
    # Define arc colours
    colour = d3.scale.ordinal().range(["#21682F", "#7E3420", "#AC7126", "#3E152A", "#1E2556", "#538A32", "#56111B", "#6C275B"]);
    # Define arc ranges
    arcText = d3.scale.ordinal().rangeRoundBands([
      0
      width
    ], .1, .3)
    # Determine size of arcs
    arc = d3.svg.arc().innerRadius(radius - 60).outerRadius(radius - 0)

    # Create the donut pie chart layout
    pie = d3.layout.pie().value((d) ->
      100 / $scope.donutChartData.length
    ).sort(null)

    # Append SVG attributes and append g to the SVG
    svg = d3.select('#donut-chart').attr('viewBox', "0 0 500 500").attr('width', '100%').append('g').attr('role', 'menu').attr('transform', 'translate(' + radius + ',' + radius + ')')

    # Define inner circle
    svg.append('circle').attr('cx', 0).attr('cy', 0).attr('r', 100).attr 'fill', '#fff'

    # Define paths for text placement
    defs = svg.append('defs')
    defs.append('path').attr('id', 'arc0').attr('d', 'M1.5308084989341916e-14,-250A250,250 0 0,1 176.77669529663692,-176.77669529663686L134.35028842544406,-134.350288425444A190,190 0 0,0 1.1634144591899855e-14,-190Z')
    defs.append('path').attr('id', 'arc1').attr('d', 'M176.77669529663692,-176.77669529663686A250,250 0 0,1 250,5.551115123125783e-14L190,4.218847493575595e-14A190,190 0 0,0 134.35028842544406,-134.350288425444Z')
    defs.append('path').attr('id', 'arc2').attr('d', 'M176.77669529663692,-176.77669529663686A250,250 0 0,1 250,5.551115123125783e-14L190,4.218847493575595e-14A190,190 0 0,0 134.35028842544406,-134.350288425444Z').attr('transform', 'translate(-50, -20) scale(1, -1)')
    defs.append('path').attr('id', 'arc3').attr('d', 'M1.5308084989341916e-14,-250A250,250 0 0,1 176.77669529663692,-176.77669529663686L134.35028842544406,-134.350288425444A190,190 0 0,0 1.1634144591899855e-14,-190Z').attr('transform', 'translate(-20, -50) scale(1, -1)')
    defs.append('path').attr('id', 'arc4').attr('d', 'M-176.77669529663675,-176.776695296637A250,250 0 0,1 1.7612034995700555e-13,-250L1.3385146596732423e-13,-190A190,190 0 0,0 -134.35028842544392,-134.35028842544412Z').attr('transform', 'translate(20, -50) scale(1, -1)')
    defs.append('path').attr('id', 'arc5').attr('d', 'M-250,-1.9142843494634747e-13A250,250 0 0,1 -176.77669529663675,-176.776695296637L-134.35028842544392,-134.35028842544412A190,190 0 0,0 -190,-1.454856105592241e-13Z').attr('transform', 'translate(50, -20) scale(1, -1)')
    defs.append('path').attr('id', 'arc6').attr('d', 'M-250,-1.9142843494634747e-13A250,250 0 0,1 -176.77669529663675,-176.776695296637L-134.35028842544392,-134.35028842544412A190,190 0 0,0 -190,-1.454856105592241e-13Z')
    defs.append('path').attr('id', 'arc7').attr('d', 'M-176.77669529663675,-176.776695296637A250,250 0 0,1 1.7612034995700555e-13,-250L1.3385146596732423e-13,-190A190,190 0 0,0 -134.35028842544392,-134.35028842544412Z')


    # Calculate SVG paths and fill in the colours
    g = svg.selectAll('.arc').data(pie($scope.donutChartData)).enter().append('g').attr('class', 'arc').attr('role', 'menuitem').on('click', (d, i) ->
      $scope.centerData = $scope.donutChartData[i]
      $scope.$apply()
    )

    # Append the path to each g- this is what draws chart on page
    g.append('path').attr('d', arc).attr 'fill', (d, i) ->
      colour i

    # Append the labels for each section
    g.append('text').style('text-anchor', 'middle').attr("dx", 98).attr("dy", 30).append('textPath').attr "xlink:href", (d, i) ->
      '#arc'+ i
    .append('tspan').attr 'id', (d, i) ->
      'tPath'+ i
    .attr('fill', '#FFF').text (d, i) ->
      $scope.donutChartData[i].name
    $('#tPath0, #tPath1, #tPath6, #tPath7').attr('style', 'letter-spacing: 2px;')

  $scope.sanitizeUrls = (name) ->
    name.replace(/\//, '%2F')
    encodeURIComponent(name)

  $scope.closeModal = ($event) ->
    $scope.$broadcast('closeModal', $event)

  init()

]
