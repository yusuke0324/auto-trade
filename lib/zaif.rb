class Zaif
  # ref:https://github.com/palon7/zaif-ruby/blob/master/lib/zaif.rb
  require 'json'
  require 'openssl'
  require 'uri'
  require 'net/http'
  include HTTParty

  BASE_TRADE_ENDPOINT = 'https://api.zaif.jp/tapi'
  BASE_PUBLIC_ENDPOINT = 'https://api.zaif.jp/api/1/'

  # get key and secret from env file
  KEY = ENV['ZAIF_KEY']
  SECRET = ENV['ZAIF_SECRET']

  def get_headers(body)
    sign = OpenSSL::HMAC::hexdigest(OpenSSL::Digest.new('sha512'), SECRET, body)
    headers = {
      'key' => KEY,
      'sign' => sign
    }
  end

  def post(url, method, data={})
    data['nonce'] = Time.now.to_f.to_i
    # method is a method for Rest not HTTP like get or post
    data['method'] = method
    p body = encode_data(data)
    headers = get_headers(body)
    response = HTTParty.post(url, headers: headers, body: body).parsed_response
  end

  def get(url, method)
    response = HTTParty.get(url + method).parsed_response
  end

  def encode_data(data)
    uri = Addressable::URI.new
    uri.query_values = data
    uri.query
  end
# get price------------------------
  def get_price(product_code='btc_jpy')
    p get(BASE_PUBLIC_ENDPOINT, 'ticker/' + product_code)
  end

# get info-------------------------
  def get_info
    p post(BASE_TRADE_ENDPOINT, 'get_info')
  end
end