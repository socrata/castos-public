app.factory "flashService", ["$rootScope", "$timeout", ($rootScope, $timeout) ->
  notice: (message) ->
    $rootScope.notice = message
    $rootScope.notice_show = true
    $timeout (->
      $rootScope.notice_show = false
      return
    ), 3000
    message

  alert: (message) ->
    $rootScope.alert = message
    $rootScope.alert_show = true
    $timeout (->
      $rootScope.alert_show = false
      return
    ), 3000
    message

  clear: ->
    $rootScope.notice_show = false
    $rootScope.alert_show = false

]