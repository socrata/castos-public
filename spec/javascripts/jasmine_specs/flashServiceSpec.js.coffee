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

describe 'flashService', ->
  $rootScope = {}
  flashService = {}

  beforeEach( ->
    module 'debtwatch'
  )

  beforeEach inject(($injector) ->
    $rootScope = $injector.get('$rootScope')
    flashService = $injector.get('flashService')
  )

  describe 'notice', ->
    it 'sets the rootScope notice and the rootScope notice_show', ->
      $rootScope.notice = 'foo'
      $rootScope.notice_show = 'false'
      flashService.notice('bar')
      expect($rootScope.notice).toBe('bar')
      expect($rootScope.notice_show).toBeTruthy()

  describe 'alert', ->
    it 'sets the alert and alert_show', ->
      $rootScope.alert = 'foo'
      $rootScope.alert_show = false
      flashService.alert('bar')
      expect($rootScope.alert).toEqual('bar')
      expect($rootScope.alert_show).toBeTruthy()

  describe 'clear', ->
    it 'clears the alert and notice', ->
      $rootScope.alert_show = true
      $rootScope.notice_show = true
      flashService.clear()
      expect($rootScope.alert_show).toBeFalsy()
      expect($rootScope.notice_show).toBeFalsy()