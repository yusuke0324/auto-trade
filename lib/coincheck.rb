module Coincheck
  module_function
  require 'ruby_coincheck_client'
  # require 'openssl'
  # include HTTParty

  # BASE_ENDPOINT = 'https://coincheck.com'

  # # get key and secret from env file
  KEY = ENV['COINCHECK_KEY']
  SECRET = ENV['COINCHECK_SECRET']

  # def get_signedheaders(nonce, url, body:"")
  #   nonce = Time.now.to_i.to_s
  #   message = nonce + url + body
  #   signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), SECRET, message)

  #   headers = {
  #     'ACCESS-KEY': KEY,
  #     'ACCESS-NONCE': nonce,
  #     'ACCESS-SIGNATURE': signature,
  #   }
  # end
  @@cc = CoincheckClient.new(KEY, SECRET)
  def read_balance
    p @@cc.read_balance
  end

  def read_order_books
    p @@cc.read_order_books
  end
end