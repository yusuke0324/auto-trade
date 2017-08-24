class Bitflyer
    require 'json'
    require 'openssl'
    require 'uri'
    require 'net/http'
    include HTTParty

  attr_accessor :exchange_name
  BASE_ENDPOINT = 'https://api.bitflyer.jp'
  # get key and secret from env file
  KEY = ENV['BITFLYER_KEY']
  SECRET = ENV['BITFLYER_SECRET']

  def initialize
    @exchange_name = 'bitflyer'
  end


# make signed key to call private api with timestamp, path, body and method using seccret
  def get_signedheaders(timestamp,path,body:"",method:"POST")

    timestamp = Time.now.to_i.to_s
    # body = JSON.generate(body)
    text = timestamp + method + path + body
    sign = OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, SECRET, text)

    headers = {
      'ACCESS-KEY' => KEY,
      'ACCESS-TIMESTAMP' => timestamp,
      'ACCESS-SIGN' => sign,
      'Content-Type' => 'application/json'
    }

    # p response = HTTParty.post(url, body:body, headers:headers)
  end

# note: param '{}' and ''.to_json are gonna be error. use nil
  def convert_params_to_body(params)
    if params
      params.to_json
    else
      ""
    end
  end

  def get(path, params:nil)
    url = BASE_ENDPOINT + path
    timestamp = Time.now.to_i.to_s
    body = convert_params_to_body(params)
    headers = get_signedheaders(timestamp, path, body: body, method: 'GET')
    response = HTTParty.get(url, headers: headers, body: body).parsed_response
  end

  def post(path, params:nil)
    url = BASE_ENDPOINT + path
    timestamp = Time.now.to_i.to_s
    body = convert_params_to_body(params)
    headers = get_signedheaders(timestamp, path, body: body, method: 'POST')
    response = HTTParty.post(url, headers: headers, body: body).parsed_response
  end

# GET PRICE------------------------------------
  def get_price(product_code='BTC_JPY')
    params = {
      product_code: product_code
    }
    response = get('/v1/getboard', params: params)
    parsed_res = {
      exchange: self,
      bid: response["bids"][0]["price"],
      ask: response["asks"][0]["price"],
    }
  end

# GET BALANCE----------------------------------
  def get_balance(currency_code="BTC")
    path = '/v1/me/getbalance'
    # url = BASE_ENDPOINT + path
    # uri = URI.parse(url)
    # timestamp = Time.now.to_i.to_s
    # headers = get_signedheaders(timestamp, path, method:'GET')
    # # which is better using Net::HTTP or HTTParty??
    # # this is an example using Net::HTTP which is a little bit dirty
    # # response = HTTParty.get(url, :headers => headers).parsed_response
    # https = Net::HTTP.new(uri.host, uri.port)
    # https.use_ssl = true
    # response = https.start {
    #   https.get(uri.request_uri, headers)
    # }
    # balance_list =  JSON.parse(response.body)
    # # search currency code info from the response
    p balance_list = get(path)
    # result = {}
    # balance_list.each do |balance|
    #   if balance['currency_code'] == currency_code then
    #     result = balance
    #   end
    # end

    # result
  end

# MAKE NEW ORDER--------------------------------
  def make_new_order(order)
    # FOR TEST
    # order = {
    #   product_code: 'BTC_JPY',
    #   child_order_type: 'LIMIT',
    #   side: 'BUY',
    #   price: 370000,
    #   size: 0.01,
    #   minute_to_expire: 100,
    #   time_in_force: 'GTC'
    # }
    path = '/v1/me/sendchildorder'
    product_code_dic = {
      "btc_jpy" => "BTC_JPY"
    }
    side_dic = {
      "buy" => "BUY",
      "sell" => "SELL"
    }
    p parsed_order = {
      product_code: product_code_dic[order[:pair]],
      child_order_type: 'LIMIT',
      side: side_dic[order[:order_type]],
      price: order[:rate],
      size: order[:amount],
      minute_to_expire: 100,
      time_in_force: 'GTC'
    }
    response = post(path, params:parsed_order)
    result = {
      success: true,
      order_id: response["child_order_acceptance_id"],
    }
  end

  def order_closed?(order_id)
    # set the param looks not working
    # params = {
    #   child_order_acceptance_id: order_id
    # }
    res = get('/v1/me/getchildorders')
    for order in res
      if order["child_order_acceptance_id"] == order_id then
        if order["child_order_state"] == "ACTIVE"
          # in this case, the order is still open
          return false
        end
      end
    end
    return true

  end

  def cancel_order(order_id)
    params = {
      'product_code' => 'BTC_JPY',
      'child_order_acceptance_id' => order_id
    }
    res = post('/v1/me/cancelchildorder', params: params)
  end
#------------------------------------
  # get price info
  def getboard(product_code='BTC_JPY')
    path = '/v1/getboard'
    url = BASE_ENDPOINT + path
    p response = HTTParty.get(url, {query: product_code})
  end

  # get bitflyer status
  def getstatus
    path = '/v1/gethealth'
    url = BASE_ENDPOINT + path
    p response = HTTParty.get(url)
  end


  def getpermissions
    path = '/v1/me/getpermissions'
    url = BASE_ENDPOINT + path
    timestamp = Time.now.to_i.to_s
    # sign = makesign(timestamp, path, method:'GET')
    headers = get_signedheaders(timestamp, path, method:'GET')
    p response = HTTParty.get(url, :headers => headers)
  end
end