module CoincheckHelper
  require 'openssl'
  include HTTParty

  BASE_ENDPOINT = 'https://coincheck.com'

  # get key and secret from env file
  KEY = ENV['COINCHECK_KEY']
  SECRET = ENV['COINCHECK_SECRET']
end