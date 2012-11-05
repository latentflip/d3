require 'bus_tracker'

service = BusTracker.service(1)

stops = service.bus_stops


departures = stops.map do |s|
  s.fetch_departures!
end

p departures
