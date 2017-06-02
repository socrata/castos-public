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

describe 'landingService', ->
  landingService = {}

  beforeEach( ->
    module 'debtwatch'
  )

  beforeEach inject(($injector) ->
    landingService = $injector.get('landingService')
  )

  describe 'notice', ->
    it 'returns an object with a promise', ->
      foo = landingService.data()
      expect(foo.$promise.$$state.status).toBe(0)
