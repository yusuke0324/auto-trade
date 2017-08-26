class Coincheck
  # require 'ruby_coincheck_client'
  # ref:https://github.com/coincheckjp/ruby_coincheck_client/blob/master/lib/ruby_coincheck_client/coincheck_client.rb
  include ApplicationHelper
  attr_accessor :exchange_name
  require 'openssl'
  include HTTParty

  BASE_ENDPOINT = 'https://coincheck.com/api/'

  # # get key and secret from env file
  KEY = ENV['COINCHECK_KEY']
  SECRET = ENV['COINCHECK_SECRET']

  def initialize
    @exchange_name = 'coincheck'
  end

  def get_signedheaders(url, body)
    nonce = Time.now.to_i.to_s
    message = nonce + url + body
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), SECRET, message)

    headers = {
      'ACCESS-KEY' => KEY,
      'ACCESS-NONCE' => nonce,
      'ACCESS-SIGNATURE' => signature,
      'Content-Type' => 'application/json'
    }
  end

  def encode_data(data)
    uri = Addressable::URI.new
    uri.query_values = data
    uri.query
  end

  def post(method, data:{})
    url = BASE_ENDPOINT + method
    # body = encode_data(data)
    headers = get_signedheaders(url, data.to_json)
    response = HTTParty.post(url, headers: headers, body: data.to_json).parsed_response
  end

  def get(method, data:{})
    url = BASE_ENDPOINT + method
    # body = encode_data(data)
    headers = get_signedheaders(url, data.to_json)
    response = HTTParty.get(url, headers: headers, body: data.to_json).parsed_response
  end

  def delete(method, data:{})
    url = BASE_ENDPOINT + method
    # body = encode_data(data)
    headers = get_signedheaders(url, data.to_json)
    response = HTTParty.delete(url, headers: headers, body: data.to_json).parsed_response
  end

  # def get_price(product_code='')
  #   p get('ticker')
  # end

# it looks 'ticker' method is NOT the latest. to get the latest rate, order_books needs to be called.
  def get_price(product_code='')
    # get latest price for ask and bid from order books
    get('order_books')["asks"][0][0]
    res = get('order_books')
    result = {
      exchange: self,
      ask: res['asks'][0][0].to_f,
      bid: res['bids'][0][0].to_f
    }
  end

  def get_balance
    p get('accounts/balance')
  end

  def make_new_order(order)
    # FOR TEST
    # order = {
    #   order_type: 'buy',
    #   pair: 'btc_jpy',
    #   rate: 1,
    #   amount: 1
    # }
    p order
    res = post('exchange/orders', data:order)
    result = {
      success: res['success'],
      order_id: res['id']
    }
  end

  def order_closed?(order_id)
    res = get('exchange/orders/opens')
    result = true
    if res['success'] then
      res['orders'].each do |order|
        if order['id'] == order_id.to_i then
          result = false
        end
      end
    end

    result
  end

  def cancel_order(order_id)
    res = delete('exchange/orders/' + order_id.to_s)
    # {"success"=>true, "id"=>204097497}
    res['success']
  end

  def has_budget?(jpy_budget, btc_budget)
    res = get('accounts/balance')
    (jpy_budget < res['jpy'].to_f) && (btc_budget < res['btc'].to_f)
  end
  # @@cc = CoincheckClient.new(KEY, SECRET)
  # def read_balance
  #   p @@cc.read_balance
  # end

  # def read_order_books
  #   p @@cc.read_order_books
  # end
end