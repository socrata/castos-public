app.factory "bulkIssuerService", ["$resource", ($resource) ->
  $resource( "/api/v1/bulk_issuer_data.json",
    {"issuers[]": @issuers, debt_filters: @debt_filters, typeOfDebt: @typeOfDebt}
    {
      data:  {method: 'POST'}
    }
  )
]
app.factory "tabularDataService", ["$resource", ($resource) ->
  $resource( "/api/v1/bulk_issuer_data.json",
    {"issuers[]": @issuers, debt_filters: @debt_filters, typeOfDebt: @typeOfDebt, tabular_view: @tabular_view}
    {
      data:  {method: 'POST'}
    }
  )
]
