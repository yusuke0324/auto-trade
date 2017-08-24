class Quoine
  require 'json'
  require 'openssl'
  require 'uri'
  require 'net/http'
  require 'jwt'
  include HTTParty

  BASE_ENDPOINT = 'https://api.quoine.com'

  KEY = ENV['QUOINE_KEY']
  SECRET = ENV['QUOINE_SECRET']

  def initialize
    @exchange_name = 'quoine'
  end

  def get_signedheaders(path)
    auth_payload = {
      path: path,
      nonce: DateTime.now.strftime('%Q'),
      token_id: KEY
    }
    signature = JWT.encode(auth_payload, SECRET, 'HS256')
    headers = {
      'X-Quoine-API-Version' => '2',
      'X-Quoine-Auth' => signature,
      'Content-Type' => 'application/json'
    }
  end

  def get(path, data:{})
    url = BASE_ENDPOINT + path
    headers = get_signedheaders(path)
    response = HTTParty.get(url, headers: headers, body: data.to_json).parsed_response
  end

  def post(path, data:{})
    url = BASE_ENDPOINT + path
    headers = get_signedheaders(path)
    response = HTTParty.post(url, headers: headers, body: data.to_json).parsed_response
  end

  def get_balance
    get('/accounts/balance')
  end

  def get_price(product_code=5)
    res = get('/products/' + product_code.to_s + '/price_levels')
    result = {
      exchange: self,
      ask:res['sell_price_levels'][0][0].to_f,
      bid:res['buy_price_levels'][0][0].to_f,
    }
  end

  def make_new_order(order)

    product_id_doc = {
      "btc_jpy" => 5
    }

    parsed_order = {
      order_type: "limit",
      # product_id is int (is it gonna be str in json any way?)
      product_id: product_id_doc[order[:pair]].to_i,
      side: order[:order_type],
      # quantity and price are string
      quantity: order[:amount].to_s,
      price: order[:rate].to_s
    }
    # work in progress!!!
    res = post('/orders/')
  end

  def get_products
    res = get('/products')

  end

end