app.factory "issuerTypeByGroupName", ["$resource", ($resource) ->
  $resource( "/api/v1/issuer_types_by_issuer_group/:issuer_group.json",
    {}
    {
      data:  {method: 'GET'}
    }
  )
]
app.factory "issuersByIssuerType", ["$resource", ($resource) ->
  $resource( "/api/v1/issuers_by_issuer_type/:issuer_type.json",
    {}
    {
      data:  {method: 'GET'}
    }
  )
]
