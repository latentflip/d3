require 'json'

users = JSON.parse File.read('followers.json')

users = users['ids']

def request(id)
  `curl "http://api.twitter.com/1/users/show.json?user_id=#{id}" > data/#{id}.json`
  `echo "," >> data/#{id}.json`
  x = `cat data/#{id}.json`
  if x =~ /rate limit/i
    throw 'Rate limit exceeded'
    `rm data/#{id}.json`
  else
    puts `cat data/#{id}.json`
  end
end

users.each do |id|
  filename = File.dirname(__FILE__) + "/data/#{id}.json"
  if File.exists?(filename)
    puts "#{filename} exists"
  else
    puts "Requesting #{filename}"
    request(id)
  end
end

