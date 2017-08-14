class Bittrex
  # NOTICE: All requests are GET!
  # ref:https://github.com/mwerner/bittrex/blob/master/lib/bittrex/client.rb
  require 'json'
  require 'openssl'
  require 'uri'
  require 'net/http'
  include HTTParty

  BASE_ENDPOINT = 'https://bittrex.com/api/v1.1'
  # get key and secret from env file
  KEY = ENV['BITTREX_KEY']
  SECRET = ENV['BITTREX_SECRET']

  def get(path, params={})
    nonce = Time.now.to_i
    url = BASE_ENDPOINT + path
    params[:apikey] = KEY
    params[:nonce] = nonce
    headers = get_headers(url, nonce)
    response = HTTParty.get(url, headers:headers, query: params)
  end

  def get_headers(url, nonce)
    sign = OpenSSL::HMAC.hexdigest('sha512', SECRET, "#{url}?apikey=#{KEY}&nonce=#{nonce}")
    headers = {
      'apisign' => sign
    }
  end

  def get_price(product_code='BTC-ETH')
    path = '/public/getticker'
    params = {
      'market' => product_code
    }
    res = get(path, params).parsed_response['result']
    result = {
      exchange: self,
      bid: res['Bid'],
      ask: res['Ask'],
      last: res['Last']
    }
  end

  def make_new_order(order)
    # FOR TEST
    # order = {
    #   market: 'BTC-ETH',
    #   quantity: 1,
    #   rate: 1
    # }
  end

  def get_balance(currency_code='BTC')
    path = '/account/getbalances'
    balance_list = get(path).parsed_response['result']
    result = {}
    balance_list.each do |balance|
      if balance['Currency'] == currency_code then
        result = balance
      end
    end

    result
  end
end