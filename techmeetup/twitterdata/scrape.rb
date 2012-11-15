require 'set'
require 'json'
require 'pstore'
require 'uri'

class Followings
  def self.for(screen_name)
    json = `curl http://api.twitter.com/1/followers/ids.json?screen_name=#{screen_name}`
    following_ids = JSON.parse(json)['ids']
    following_ids
  end
end

class ExtendedInfo
  def self.for(screen_name)
    json = `curl http://api.twitter.com/1/users/show.json?screen_name=#{screen_name}&include_entities=true`
    JSON.parse(json)
  end
end

class Locate
  def self.user(u)
    if u['status'] && u['status']['coordinates'] && u['status']['coordinates']['coordinates']
      return u['status']['coordinates']['coordinates']
    end

    address = URI::encode u['location']
    if address
      address = URI::encode address
      locjson = JSON.parse `curl "http://maps.googleapis.com/maps/api/geocode/json?address=#{address}&sensor=false"`
      if latlong = locjson['results'] && locjson['results'][0] && locjson['results'][0]['geometry'] && locjson['results'][0]['geometry']['location']
        return [latlong['lng'], latlong['lat']]
      end
    end
    
  end
end


class Scrape
  attr_reader :store

  def initialize
    @store = PStore.new('users.pstore')
  end

  def read(&blk)
    store.transaction(true, &blk)
  end
  def update(&blk)
    store.transaction &blk
  end

  def save_new_users
    users = File.read('./user_list.txt').split.map { |u| u.gsub /^@/, '' }
    update do
      store[:users] ||= {}
      users.each do |user|
        store[:users][user] ||= {}
      end
    end
  end

  def save_followings
    users = read { store[:users] }
    users.each do |screen_name, hash|
      puts screen_name
      unless hash[:following]
        following = Followings.for(screen_name) || []
        puts "Updated following for #{screen_name} to #{following[0..10].join(', ')}"
        update { store[:users][screen_name][:following] = following }
      end
    end
  end

  def save_user_info
    users = read { store[:users] }
    users.each do |screen_name, hash|
      unless hash[:extended_info]
        info = ExtendedInfo.for(screen_name)
        if id = info['id']
          p info
          update {
            store[:users][screen_name][:id] = id
            store[:users][screen_name][:extended_info] = info
          }
        end
      end
    end
  end
  
  def locate_users
    users = read { store[:users] }
    users.each do |screen_name, hash|
      puts screen_name
      unless hash[:coords]
        puts hash[:extended_info]
        if location = Locate.user(hash[:extended_info])
          p location
          update {
            store[:users][screen_name][:coords] = location
          }
        end
      end
    end
  end

  def delete_user
    update {
      store[:users].delete('iffanghu')
    }
  end


  def dump_store
    read do
      store[:users]
    end
  end

  def users_json
    users = read { store[:users] }
    output = {}
    output[:users] = users.map do |screen_name, u|
      {
        :screen_name => screen_name,
        :id => u[:id],
        :coords => u[:coords],
        :name => u[:extended_info]['name'],
        :signed_up => u[:extended_info]['created_at'],
        :statuses_count => u[:extended_info]['statuses_count'],
        :friends_count => u[:extended_info]['friends_count'],
        :followers_count => u[:extended_info]['followers_count'],
        :avatar => u[:extended_info]['profile_image_url'],
        :color => u[:extended_info]['profile_text_color']
      }
    end
  end

  def links_json
    users = read { store[:users] }
    users_by_id = {}.tap do |h|
      users.each do |name,u|
        h[ u[:id] ] = u
      end
    end
    
    links = []
    users_by_id.each do |id,info|
      following = info[:following]

      users_by_id.each do |other_id, other_info|
        if following.include? other_id
          my_set = Set.new(following)
          their_set = Set.new(other_info[:following])
          links << {:source => id, :target => other_id, :value => (my_set&their_set).length }
        end
      end
    end
    links
  end
end

s = Scrape.new

s.delete_user
s.save_new_users
s.save_followings
s.save_user_info
s.locate_users

File.open('users.json', 'w+') do |f|
  f.write JSON.dump(s.users_json)
end
File.open('links.json', 'w+') do |f|
  f.write JSON.dump(s.links_json)
end
