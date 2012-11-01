require 'bus_tracker'
require 'json'

buses = ["CS1", "ET1", "MA1", "WHT", "BOAT", "1", "2", "3", "4", "5", "7", "8", "10", "11", "12", "X12", "14", "15", "15A", "16", "18", "19", "20", "21", "22", "23", "24", "25", "X25", "26", "X26", "27", "29", "X29", "30", "31", "X31", "32", "33", "34", "35", "36", "37", "X37", "38", "39", "40", "41", "42", "44", "44A", "X44", "45", "47", "49", "61", "67", "69", "100", "109", "113", "C134", "N3", "N11", "N16", "N22", "N25", "N26", "N30", "N31", "N34", "N37", "N44"]

def get_bus_stops(service_number)
  stops = BusTracker.service(service_number).bus_stops
  stops.map! do |stop|
    attrs = [:name, :code, :latitude, :longitude, :service_numbers]

    {}.tap do |h|
      attrs.each do |a|
        h[a] = stop.send a
      end
    end
  end

  File.open("stop_#{service_number}.json", 'w+') do |f|
    f.write "var Stops = Stops || {};"
    f.write "Stops['#{service_number}'] = #{JSON.dump(stops)};";
  end
end


buses.each do |bus|
  get_bus_stops(bus)
end
