class Kraken
    require 'json'
    require 'addressable/uri'
    require 'openssl'
    require 'uri'
    require 'net/http'
    require 'hashie'
    require 'base64'
    require 'securerandom'

    include HTTParty
# [ref]https://github.com/yusuke0324/kraken_ruby/blob/master/lib/kraken_ruby/client.rb
  # get key and secret from env file
  KEY = ENV['KRAKEN_KEY']
  SECRET = ENV['KRAKEN_SECRET']

  BASE_ENDPOINT = 'https://api.kraken.com'

  def initialize()
    @api_version = "0"
  end

  def get_signedheaders(path, data, nonce)
    key = Base64.decode64(SECRET)
    digest = OpenSSL::Digest.new('sha256', nonce + data).digest
    message = path + digest
    hmac_message = Base64.strict_encode64(OpenSSL::HMAC.digest('sha512', key, message))
    headers = {
      'API-Key' => KEY,
      'API-Sign' => hmac_message,
      'Content-Type' => 'application/json'
    }
  end

  def nonce
    high_bits = (Time.now.to_f * 10000).to_i << 16
    low_bits  = SecureRandom.random_number(2 ** 16) & 0xffff
    (high_bits | low_bits).to_s
  end

  def post_private(method, data={})
    path = url_path(method)
    url = BASE_ENDPOINT + path
    nonce_val = nonce
    post_data = encode_data(data)
    headers = get_signedheaders(path, post_data, nonce_val)

    response = HTTParty.post(url, headers: headers, body: post_data)
  end

  def get_public(method, data={})
    url = BASE_ENDPOINT + '/' + @api_version + '/public/' + method
    res = HTTParty.get(url, query: data).parsed_response
  end

  def url_path(method)
    '/' + @api_version + '/private/' + method
  end

  def get_time
    get_public('Time')
  end

  def encode_data(data)
    uri = Addressable::URI.new
    uri.query_values = data
    uri.query
  end

  def get_balance
    p post_private('Balance')
  end
end