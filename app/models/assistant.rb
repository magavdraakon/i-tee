require "net/http"
require "uri"
require "json"

class Assistant < ActiveRecord::Base
  attr_accessible :enabled, :uri, :name, :version
  has_many :labs

  validates_presence_of :name, :uri
  validates_uniqueness_of :uri

  # not used?
  def get_lab(params={})
    result = self.get_request("/api/v1/lab", params)
    result
  end

# used in start_lab
# {"api_key": lab.lab_token , "lab": lab.lab_hash, "username": user.username, "fullname": user.name, "password": password,  "host": rdp_host , "info":{"somefield": "somevalue"}}
# expects key field
  def create_labuser(params={})
    result = false
    case self.version
    when 'v1'
      result = self.post_request("/api/v1/labuser", params)
    when 'v2'
      data = {
        labID: params[:lab],
        api_key: params[:api_key],
        username: params[:username],
        fullname: params[:fullname],
        password: params[:password],
        host: params[:host]
      }
      lu = self.post_request("/api/v2/labusers", data)
      if !lu.blank? && lu.key?('userKey')
        result = {'key' => lu['userKey']}
      else # get user key manually
        data = { username: params[:username] }
        users = self.get_request("/api/v2/users", data)
        unless users.is_a?(Hash) && users.key?('error')
          user = users.first
          if user.key?('url_token')
            result = {'key' => user['url_token'] }
          end
        end
      end
    end
    result
  end

  ### #### API CALLS #### ###
  def get_request(path, params)
    self.request_json :get, path, params
  end

  def post_request(path, params)
    self.request_json :post, path, params
  end

  def put_request(path, params)
    self.request_json :put, path, params
  end

  def delete_request(path, params)
    self.request_json :delete, path, params
  end

  def request_json(method, path, params)
    response = self.request(method, path, params)
    if response && response.body
      body = JSON.parse(response.body)
    else
      false # query failed
    end
  rescue JSON::ParserError
    response
  end

  def request(method, path, params = {})
    if params[:api_key].blank? # always add master admin token if none specified in params
      params.merge!({ :api_key => self.token })
    end
    uri = URI.parse(self.uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 500 # seconds
    if uri.scheme == 'https'
      http.use_ssl = true
      if Rails.env == 'development'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: IMPORTANT!! read into this
      end
    end

    verbs = {
      :get => Net::HTTP::Get,
      :post => Net::HTTP::Post,
      :put => Net::HTTP::Put,
      :delete => Net::HTTP::Delete
    }
    request = verbs[method.to_sym].new(path, { 'Content-Type' => 'application/json' })
    request.body = params.to_json
    http.request(request)
  end

  # assistant responds with 200
  def host_exists?(uri = '', redirects = 0)
    uri = URI.parse(uri == '' ? self.uri : uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 10 # seconds
    if uri.scheme == 'https'
      http.use_ssl = true
      if Rails.env == 'development'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: IMPORTANT!! read into this
      end
    end
    path = "/"
    params={ :auth_token => self.token } # always add admin token

    full_path = encode_path_params(path, params)
    request = Net::HTTP::Get.new(full_path) # try and load the front page

    request.body = params.to_json
    res = http.request(request)
    if res && res.kind_of?(Net::HTTPRedirection)
      logger.debug "\n host redirected  #{self.uri} #{redirects} times"
      if redirects<5
        host_exists?(res['location'], redirects+1) # Go after any redirect and make sure you can access the redirected URL
      else
        logger.error "\n host redirected too many times #{self.uri} (#{redirects} times)"
        false
      end
    else
      logger.error "\n return code #{res.code} #{self.uri}"
      !%W(4 5).include?(res.code[0]) # Not from 4xx or 5xx families
    end
  rescue Errno::ENOENT
    logger.error "\nENOENT: error #{self.uri}"
    false #false if can't find the server
  rescue Errno::ECONNREFUSED
    logger.error "\nECONNREFUSED: error #{self.uri}"
    false # connection refused
  rescue Exception => e
    logger.error "\nException: #{self.uri} - #{e}\n"
    false
  end

  private

  def encode_path_params(path, params)
    encoded = URI.encode_www_form(params)
    [path, encoded].join("?")
  end
end
