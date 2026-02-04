class ForecastsController < ApplicationController
  def index
    @address = params[:address].to_s.strip
    return if @address.blank?

    geocoding = GeocodingService.lookup(@address)
    if geocoding.nil?
      @error = "We couldn't locate that address. Please try a more specific address."
      return
    end

    @resolved_address = geocoding[:address]
    @zip = geocoding[:zip]

    if @zip.present?
      cache_key = "forecast:zip:#{@zip}"
      cached = Rails.cache.read(cache_key)
      if cached
        @forecast = cached
        @from_cache = true
      else
        @forecast = WeatherService.fetch(lat: geocoding[:latitude], lon: geocoding[:longitude])
        Rails.cache.write(cache_key, @forecast, expires_in: 30.minutes)
        @from_cache = false
      end
    else
      @forecast = WeatherService.fetch(lat: geocoding[:latitude], lon: geocoding[:longitude])
      @from_cache = false
      @cache_note = "ZIP not found; caching skipped."
    end
  rescue WeatherService::Error => e
    @error = e.message
  end
end
