app.value("googleChartApiConfig",
  version: "1"
  optionalSettings:
    packages: ["corechart", "annotationchart"]
).provider("googleJsapiUrl", ->
  protocol = "https:"
  url = "//www.google.com/jsapi"
  @setProtocol = (newProtocol) ->
    protocol = newProtocol
    return

  @setUrl = (newUrl) ->
    url = newUrl
    return

  @$get = ->
    ((if protocol then protocol else "")) + url

  return
).factory("googleChartApiPromise", [
  "$rootScope"
  "$q"
  "googleChartApiConfig"
  "googleJsapiUrl"
  ($rootScope, $q, apiConfig, googleJsapiUrl) ->
    apiReady = $q.defer()
    onLoad = ->
      settings = callback: ->
        oldCb = apiConfig.optionalSettings.callback
        $rootScope.$apply ->
          apiReady.resolve()
          return

        oldCb.call this  if angular.isFunction(oldCb)
        return

      settings = angular.extend({}, apiConfig.optionalSettings, settings)
      window.google.load "visualization", apiConfig.version, settings
      return

    head = document.getElementsByTagName("head")[0]
    script = document.createElement("script")
    script.setAttribute "type", "text/javascript"
    script.src = googleJsapiUrl
    if script.addEventListener
      script.addEventListener "load", onLoad, false
    else
      script.onreadystatechange = ->
        if script.readyState is "loaded" or script.readyState is "complete"
          script.onreadystatechange = null
          onLoad()
        return
    head.appendChild script
    return apiReady.promise
])
