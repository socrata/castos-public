app.factory "landingService", ["$resource", ($resource) ->
  $resource( "/api/v1/landing_page_info.json",
    {}
    {
      data:  {method: 'GET'}
    }
  )
]