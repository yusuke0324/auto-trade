class Bitflyer
    require 'json'
    require 'openssl'
    require 'uri'
    require 'net/http'
    include HTTParty

  BASE_ENDPOINT = 'https://api.bitflyer.jp'
  # get key and secret from env file
  KEY = ENV['BITFLYER_KEY']
  SECRET = ENV['BITFLYER_SECRET']


# make signed key to call private api with timestamp, path, body and method using seccret
  def get_signedheaders(timestamp,path,body:"",method:'POST')

    timestamp = Time.now.to_i.to_s
    # body = JSON.generate(body)
    p SECRET
    p text = timestamp + method + path + body
    p sign = OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, SECRET, text)

    headers = {
      'ACCESS-KEY' => KEY,
      'ACCESS-TIMESTAMP' => timestamp,
      'ACCESS-SIGN' => sign,
      'Content-Type' => 'application/json'
    }

    # p response = HTTParty.post(url, body:body, headers:headers)
  end

# GET PRICE------------------------------------
  def get_price(product_code='ETH_BTC')
    path = '/v1/getticker'
    url = BASE_ENDPOINT + path
    params = {
      product_code: product_code
    }
    response = HTTParty.get(url, {query: params}).parsed_response
    parsed_res = {
      exchange: self,
      bid: response["best_bid"],
      ask: response["best_ask"]
    }
  end

# GET BALANCE----------------------------------
  def get_balance(currency_code="BTC")
    path = '/v1/me/getbalance'
    url = BASE_ENDPOINT + path
    uri = URI.parse(url)
    timestamp = Time.now.to_i.to_s
    headers = get_signedheaders(timestamp, path, method:'GET')
    # which is better using Net::HTTP or HTTParty??
    # this is an example using Net::HTTP which is a little bit dirty
    # response = HTTParty.get(url, :headers => headers).parsed_response
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    response = https.start {
      https.get(uri.request_uri, headers)
    }
    balance_list =  JSON.parse(response.body)
    # search currency code info from the response
    result = {}
    balance_list.each do |balance|
      if balance['currency_code'] == currency_code then
        result = balance
      end
    end

    result
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
    url = BASE_ENDPOINT + path
    timestamp = Time.now.to_i.to_s
    headers = get_signedheaders(timestamp, path, method:'POST', body:order.to_json)
    p response = HTTParty.post(url, :headers => headers, :body => order.to_json).parsed_response
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