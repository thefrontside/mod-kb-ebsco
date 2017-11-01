require "open-uri"

class Configuration
  include ActiveModel::Validations

  attr_accessor :customer_id, :api_key

  validate :verify_credentials

  def id
    'rmapi'
  end

  def initialize(okapi, rmapi_base_url)
    @rmapi_base_url = rmapi_base_url
    @okapi = okapi
  end

  def load!
    response = @okapi.user.get '/configurations/entries?query=module=KB_EBSCO'
    response["configs"].each do |config|
      params = Rack::Utils.parse_query(config["value"])
      @customer_id = params["customer-id"]
      @api_key = params["api-key"]
    end
  end

  def verify_credentials
    uri = "%{base}/rm/rmaccounts/%{customer_id}/%{path}" % {
      base: @rmapi_base_url,
      customer_id: @customer_id,
      path: 'vendors?search=zz12&offset=1&orderby=vendorname&count=1'
    }

    open(uri, { 'X-Api-Key' => @api_key })

    return true
  rescue
    self.errors[:base] << "RM-API Credentials Are Invalid"
  end

  def save
    return false unless valid?

    response = @okapi.user.get '/configurations/entries?query=module=KB_EBSCO'

    response["configs"].each do |config|
      id = config["id"]
      @okapi.user.delete "/configurations/entries/#{id}"
    end

    @okapi.user.post(
      '/configurations/entries',
      {
       "module": "KB_EBSCO",
       "configName": "api_credentials",
       "code": "kb.ebsco.credentials",
       "description": "EBSCO RM-API Credentials",
       "enabled": true,
       "value": "customer-id=#{customer_id}&api-key=#{@api_key}"
      }
    )
  end
end