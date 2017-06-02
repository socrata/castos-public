app.factory "issuerSelectionByCountyService", ["$resource", ($resource) ->
  $resource( "/api/v1/issuers_by_county/:county.json",
    {}
    {
      data:  {method: 'GET'}
    }
  )
]
