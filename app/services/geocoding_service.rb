class GeocodingService
  ZIP_REGEX = /\b\d{5}(?:-\d{4})?\b/.freeze

  def self.lookup(address)
    cleaned = address.to_s.strip
    return nil if cleaned.empty?

    result = Geocoder.search(cleaned).first
    return nil if result.nil?

    zip = extract_zip(result, cleaned)
    {
      address: result.address,
      latitude: result.latitude,
      longitude: result.longitude,
      zip: normalize_zip(zip)
    }
  end

  def self.extract_zip(result, fallback)
    result.postal_code ||
      result.data.dig("address", "postcode") ||
      fallback[ZIP_REGEX]
  end

  def self.normalize_zip(zip)
    return nil if zip.nil?

    match = zip.to_s.match(/\d{5}/)
    match&.to_s
  end
end
