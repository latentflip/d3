require 'json'
require 'pp'
require 'open-uri'
users = JSON.parse File.read('users.json')

l = File.read('locations.json')
if l == ''
  locations = {}
else
  locations = JSON.parse(l)
end

#users with tweeted locations
located_users = users.select do |u|
  u['status'] && u['status']['coordinates'] && u['status']['coordinates']['coordinates']
end

located_users.each do |u|
  locations[ u['id'] ] = u['status']['coordinates']['coordinates']
end

def lookup_user(u)
  address = URI::encode u['location']
  if address
    address = URI::encode address
    locjson = JSON.parse `curl "http://maps.googleapis.com/maps/api/geocode/json?address=#{address}&sensor=false"`
    if latlong = locjson['results'] && locjson['results'][0] && locjson['results'][0]['geometry'] && locjson['results'][0]['geometry']['location']
      return [latlong['lng'], latlong['lat']]
    end
  end
end

users.each do |u|
  begin
    locations[u['id']] ||= lookup_user(u)
  rescue Exception => e
    puts e.message
  end
end

locations.each do |k,v|
  locations.delete(k) unless v
end

File.open('locations.json', 'w+') do |f|
  f.write JSON.dump(locations)
end
