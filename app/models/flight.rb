class Flight < ActiveRecord::Base
  has_many :data_points

  SEA_LEVEL_PRESSURE = 1013.25 #mbars

  def self.travel_distance(starting_point, ending_point)
    rad_per_deg = Math::PI/180.0  # PI / 180
    rkm = 6371.0                  # Earth radius in kilometers
    rm = rkm * 1000.0             # Radius in meters

    dlon_rad = (ending_point[1] - starting_point[1]) * rad_per_deg  # Delta, converted to rad
    dlat_rad = (ending_point[0] - starting_point[0]) * rad_per_deg

    lat1_rad, lon1_rad = starting_point.map! {|i| i * rad_per_deg }
    lat2_rad, lon2_rad = ending_point.map! {|i| i * rad_per_deg }

    starting_point = Math.sin(dlat_rad/2.0)**2.0 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2.0)**2.0
    c = 2.0 * Math::atan2(Math::sqrt(starting_point), Math::sqrt(1.0-starting_point))

    rm * c / 1000 # Delta in km
  end

  def self.parse_habhub(json)
    new_hash = {}
    new_hash[:altitude] = json["altitude"]
    new_hash[:latitude] = json["latitude"]
    new_hash[:longitude] = json["longitude"]
    new_hash[:temperature] = json["temperature_external"] || json["temperature"] || json["external_temperature"]
    new_hash[:battery] = json["battery"]
    new_hash[:time] = json["time"]
    new_hash[:humidity] = json["humidity"]
    json['pressure'] ? new_hash[:pressure] = json['pressure'] : new_hash[:pressure] = calculate_pressure(json)
    new_hash.to_json
  end

  def self.calculate_pressure(json)
    altitude = json["altitude"]
    ((SEA_LEVEL_PRESSURE * 100) * (1 - (2.25577 * 10**(-5) * altitude))**5.25588) / 100
  end

  def self.callsign(sentence)
    sentence[2..(sentence.index(',')-1)]
  end

  def self.create_data(json_flight_data, flight)
    json_flight_data.each do |point|
      DataPoint.create!(flight_id: flight.id, data: parse_habhub(point)) unless point["altitude"] == 0 || point["latitude"] == 0.0
    end
  end

  def self.import_habhub(files)
    files.each do |file|
      json_flight_data = JSON.load File.new(file)
      sentence = json_flight_data.first["_sentence"]
      flight = Flight.create!(callsign: callsign(sentence))
      create_data(json_flight_data, flight)
      update_flight(flight)
    end
  end

  def self.update_flight(flight)
    max_flight = flight.data_points.max_by { |p| p.data["altitude"] }
    max_altitude = max_flight.data["altitude"]

    start_time = Time.parse(flight.data_points.first.data['time'])
    end_time = Time.parse(flight.data_points.last.data['time'])
    total_seconds = end_time - start_time
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)

    time = format("%02d:%02d:%02d", hours, minutes, seconds)

    start_lat = flight.data_points.first.data['latitude']
    start_long = flight.data_points.first.data['longitude']
    end_lat = flight.data_points.last.data['latitude']
    end_long = flight.data_points.last.data['longitude']

    puts start_lat
    puts start_long
    puts end_lat
    puts end_long

    distance = travel_distance([start_lat.to_f, start_long.to_f], [end_lat.to_f, end_long.to_f])

    flight.update(max_altitude: max_altitude, duration: "#{time}", distance_traveled: distance)
  end

  def self.import_habhub_from_url(url)
	  json_flight_data = Crack::JSON.parse(RestClient.get(url))
	  sentence = json_flight_data.first["_sentence"]
	  flight = Flight.create!(callsign: callsign(sentence))
	  create_data(json_flight_data, flight)
	  update_flight(flight)
  end
end
