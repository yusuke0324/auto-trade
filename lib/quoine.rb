class Quoine
  require 'json'
  require 'openssl'
  require 'uri'
  require 'net/http'
  include HTTParty

  BASE_ENDPOINT = 'https://api.quoine.com'

  KEY = ENV['QUOINE_KEY']
  SECRET = ENV['QUOINE_SECRET']
end