module BitflyerHelper
  require 'json'
  require 'openssl'
  include HTTParty

  BASE_ENDPOINT = 'https://api.bitflyer.jp'
  # get key and secret from env file
  KEY = ENV['BITFLYER_KEY']
  SECRET = ENV['BITFLYER_SECRET']
  # get price info
  def getboard(product_code='BTC_JPY')
    path = '/v1/getboard'
    url = BASE_ENDPOINT + path
    p resonse = HTTParty.get(url, {query: product_code})
  end

  # get bitflyer status
  def getstatus
    path = '/v1/gethealth'
    url = BASE_ENDPOINT + path
    p resonse = HTTParty.get(url)
  end

# make signed key to call private api with timestamp, path, body and method using seccret
  def get_signedheaders(timestamp,path,body:"",method:'POST')

    timestamp = Time.now.to_i.to_s
    # body = JSON.generate(body)
    p SECRET
    p text = timestamp + method + path + body
    p sign = OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, SECRET, text)

    headers = {
      'ACCESS-KEY': KEY,
      'ACCESS-TIMESTAMP': timestamp,
      'ACCESS-SIGN': sign,
      'Content-Type': 'application/json'
    }

    # p response = HTTParty.post(url, body:body, headers:headers)
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