module ApplicationHelper
  include HTTParty

  BASE_ENDPOINT = 'https://api.bitflyer.jp/v1/'
  # get all products
  def getmarkets
    method = 'getmarkets'
    url = BASE_ENDPOINT + method
    p response = HTTParty.get(url)
  end

end
