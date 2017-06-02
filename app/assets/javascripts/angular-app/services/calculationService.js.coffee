app.factory "calculationByIssuerService", ["$resource", ($resource) ->
  $resource( "/api/v1/calculate_sums_by_issuer.json",
    {}
    {
      data:  {method: 'POST'}
    }
  )
]
