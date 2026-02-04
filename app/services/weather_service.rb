require "net/http"
require "json"

class WeatherService
  class Error < StandardError; end

  BASE_URL = "https://api.weather.gov".freeze
  USER_AGENT = ENV.fetch("NWS_USER_AGENT", "forecast_app (contact: you@example.com)")
  ACCEPT_HEADER = "application/geo+json".freeze

  def self.fetch(lat:, lon:)
    point = get_json("#{BASE_URL}/points/#{lat},#{lon}")
    forecast_url = point.dig("properties", "forecast")
    hourly_url = point.dig("properties", "forecastHourly")

    raise Error, "Forecast URL missing from NWS response." if forecast_url.nil?

    forecast = get_json(forecast_url)
    hourly = hourly_url ? get_json(hourly_url) : nil

    build_payload(forecast, hourly)
  end

  def self.get_json(url, limit: 3)
    raise Error, "Too many redirects from NWS." if limit <= 0

    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT
    request["Accept"] = ACCEPT_HEADER

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 10

    response = http.request(request)

    if response.is_a?(Net::HTTPRedirection)
      location = response["location"]
      raise Error, "NWS redirect missing location header." if location.nil?

      redirected_url = URI.join(url, location).to_s
      return get_json(redirected_url, limit: limit - 1)
    end

    if response.is_a?(Net::HTTPNotFound)
      raise Error, "NWS has no data for this location. The NWS API only covers U.S. addresses."
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "NWS request failed (HTTP #{response.code})."
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise Error, "Unexpected response from NWS: #{e.message}"
  end

  def self.build_payload(forecast, hourly)
    forecast_periods = Array(forecast.dig("properties", "periods"))
    hourly_periods = Array(hourly&.dig("properties", "periods"))

    current_period = hourly_periods.first || forecast_periods.first

    {
      updated_at: forecast.dig("properties", "updated"),
      current: current_payload(current_period),
      high_low: high_low_payload(hourly_periods),
      periods: forecast_periods.first(6).map { |period| period_payload(period) }
    }
  end

  def self.current_payload(period)
    return {} if period.nil?

    {
      name: period["name"],
      temperature: period["temperature"],
      unit: period["temperatureUnit"],
      short_forecast: period["shortForecast"],
      time: period["startTime"]
    }
  end

  def self.high_low_payload(hourly_periods)
    temps = hourly_periods.first(24).map { |period| period["temperature"] }.compact
    return {} if temps.empty?

    {
      high: temps.max,
      low: temps.min,
      unit: hourly_periods.first["temperatureUnit"]
    }
  end

  def self.period_payload(period)
    {
      name: period["name"],
      temperature: period["temperature"],
      unit: period["temperatureUnit"],
      short_forecast: period["shortForecast"]
    }
  end
end
