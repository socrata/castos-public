class CacheManager
  # Hash of data retrieval methods in DebtWatch, matched to the the string used
  #   as a key when caching the results of said method
  CACHE_METHOD_NAMES = {
    county_map_info:              'map_info',
    landing_page_content:         'static_landing_page_content',
    carousel_content:             'carousel_content',
    issuer_group_wheel:           'get_issuer_groups',
    selection_page_data:          'selection_page_data',
    issuer_types_by_issuer_group: 'issuer_types_by_issuer_group',
    issuers_by_issuer_type:       'issuers_by_issuer_type',
    issuers_by_county:            'issuers_by_county',
    get_debt_for_issuers:         'get_debt_for_issuers'
  }

  def cache(name:, ttl: 12.hours)
    data = Rails.cache.fetch(name, expires_in: ttl) do
      yield
    end

    data
  # If there is any kind of error raised by the Socrata client, catch it and
  #   make sure we're not caching the error result by manually deleting the
  #   cache for that attempt
  rescue StandardError => e
    Rails.cache.delete(name)
    { error: e.message }
  end
end
