class Coincheck
  # require 'ruby_coincheck_client'
  # ref:https://github.com/coincheckjp/ruby_coincheck_client/blob/master/lib/ruby_coincheck_client/coincheck_client.rb
  require 'openssl'
  include HTTParty

  BASE_ENDPOINT = 'https://coincheck.com/api/'

  # # get key and secret from env file
  KEY = ENV['COINCHECK_KEY']
  SECRET = ENV['COINCHECK_SECRET']

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
    body = encode_data(data)
    headers = get_signedheaders(url, body)
    response = HTTParty.post(url, headers: headers, body: body).parsed_response
  end

  def get(method, data:{})
    url = BASE_ENDPOINT + method
    body = encode_data(data)
    p headers = get_signedheaders(url, body)
    response = HTTParty.get(url, headers: headers).parsed_response
  end

  def get_price(product_code='')
    p get('ticker')
  end

# it looks 'ticker' method is NOT the latest. to get the latest rate, order_books needs to be called.
  def get_orderbooks(product_code='')
    p get('order_books')["asks"][0][0]
    p get('ticker')['ask']
  end

  def get_balance
    p get('/accounts/balance')
  end
  # @@cc = CoincheckClient.new(KEY, SECRET)
  # def read_balance
  #   p @@cc.read_balance
  # end

  # def read_order_books
  #   p @@cc.read_order_books
  # end
end