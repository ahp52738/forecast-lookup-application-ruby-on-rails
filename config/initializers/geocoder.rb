Geocoder.configure(
  lookup: :nominatim,
  use_https: true,
  timeout: 5,
  params: { addressdetails: 1 },
  http_headers: {
    "User-Agent" => ENV.fetch("GEOCODER_USER_AGENT", "forecast_app")
  }
)
