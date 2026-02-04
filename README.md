# Forecast App

Simple Rails app that accepts an address, resolves it to coordinates, and fetches
the latest forecast. Results are cached for 30 minutes by ZIP code.

## Requirements

- Ruby 3.2+
- Rails 8.0+

## Setup

```bash
bundle install
bin/rails db:prepare
```

## Environment variables

The National Weather Service API expects a descriptive User-Agent with contact
info. Set this to your email or project contact address.

The geocoding lookup uses Nominatim; it also requires a valid User-Agent.

```bash
export NWS_USER_AGENT="forecast_app (contact: you@example.com)"
export GEOCODER_USER_AGENT="forecast_app (contact: you@example.com)"
```

## Run the app

```bash
bin/rails server
```

Then visit `http://localhost:3000`.

## Notes

- Forecast data is pulled from the National Weather Service API (U.S. coverage).
- Cached entries are keyed by ZIP code and expire after 30 minutes.
