require 'rest-client'
require 'json'
require 'addressable/uri'
require 'nokogiri'

$API_KEY = "AIzaSyCYPxYNe44BjNBzrqz0qRN3nGkKip_yELc"

def run
  user_location = get_user_location
  user_pinpoint = find_location(user_location)
  stores = find_stores(user_pinpoint)
  directions = get_directions(user_pinpoint, stores)
  print_directions(directions)
end

def get_user_location
  puts "Please enter your current location:"
  gets.chomp
end

def find_location(address)
  location_url = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "maps/api/geocode/json",
     :query_values => {:address => address, :sensor => false}
   ).to_s

  returned = RestClient.get(location_url)
  response = JSON.parse(returned)

  lat = response["results"].first["geometry"]["location"]["lat"]
  lng = response["results"].first["geometry"]["location"]["lng"]
  location = "#{lat},#{lng}"
end

def find_stores(location)
  store_url = Addressable::URI.new(
    :scheme => "https",
    :host => "maps.googleapis.com",
    :path => "maps/api/place/nearbysearch/json",
    :query_values => {:key => $API_KEY, :location => location,
                      :radius => 300, :sensor => false,
                      :keyword => "ice cream"}
    ).to_s

  returned = RestClient.get(store_url)
  response = JSON.parse(returned)

  stores = []

  response["results"].each do |hash|
    stores << {:name => hash["name"], :address => hash["vicinity"]}
  end

  stores
end

def get_directions(user_location, stores)
  stores.each do |store|
    store[:directions] = directions(user_location, store[:address])
  end
  stores
end

def directions(start_location, end_location)
  directions_url = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "maps/api/directions/json",
     :query_values => {:origin => start_location, :destination => end_location,
                       :sensor => false, :mode => "walking"}
   ).to_s

   returned = RestClient.get(directions_url)
   response = JSON.parse(returned)

   instructions = []
   response["routes"].first["legs"].first["steps"].each do |hash|
     parsed_step = Nokogiri::HTML(hash["html_instructions"])
     instructions << parsed_step.text
   end
   instructions.join(". ")
end

def print_directions(directions)
  puts "Your ice cream options are:"
  puts
  directions.each do |hash|
    puts hash[:name]
    puts hash[:address]
    puts hash[:directions]
    puts
  end
end

run