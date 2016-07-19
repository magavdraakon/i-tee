require "net/http"
require "uri"
require "json"

class Http

@cookies=''
 ###   #### API CALLS ####  ### 
 def self.get_cookies(res)
	all_cookies = res.get_fields('set-cookie')
	cookies_array = Array.new
	if all_cookies && all_cookies.count>0
		all_cookies.each { | cookie |
		    cookies_array.push(cookie.split('; ')[0])
		}
		@cookies = cookies_array.join('; ')
	end
	@cookies
end


  def self.get( path, params, type='')
  	case type
  	when 'json'
    	self.request_json :get, path, params
    else
    	self.request :get, path, params
    end
  end

  def self.post( path, params, type='')
    case type
  	when 'json'
    	self.request_json :post, path, params
    else
    	self.request :post, path, params
    end
  end

  def self.put( path, params, type='')
    case type
  	when 'json'
    	self.request_json :put, path, params
    else
    	self.request :put, path, params
    end
  end

  def self.delete( path, params, type='')
    case type
  	when 'json'
    	self.request_json :delete, path, params
    else
    	self.request :delete, path, params
    end
  end

  def self.request_json(method, path, params)
    response = self.request( method, path, params)
    if response && response.body
      body = JSON.parse(response.body)
    else
      false # query failed 
    end
  rescue JSON::ParserError
    response
  end

  def self.request( method, path, params = {})
    #params.merge!({:auth_token=> self.token }) # always add admin token
    unless path.starts_with?('https://') || path.starts_with?('http://')
      path = "http://"+path
    end
    uri = URI.parse(path)
    http = Net::HTTP.new(uri.host, uri.port)
      

    if path.starts_with?('https://')
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: IMPORTANT!! read into this
    end
      
    verbs = {
      :get    => Net::HTTP::Get,
      :post   => Net::HTTP::Post,
      :put    => Net::HTTP::Put,
      :delete => Net::HTTP::Delete
    }

    #case method
    #when :get
    #  full_path = encode_path_params(path, params)
    #  request = verbs[method.to_sym].new(full_path)
    #else
    #puts "cookies are: #{@cookies}"
    request = verbs[method.to_sym].new(path, { 'Cookie' => @cookies, 'Content-Type' =>'application/x-www-form-urlencoded'})
    request.set_form_data(params)
    #request.body = params.to_json
    # end

    http.request(request)
  end

  def self.host_exists?(url_string)
    url = URI.parse( url_string )
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    path = "/"
    params={:auth_token=> self.token }

    full_path = encode_path_params(path, params)
    request = Net::HTTP::Get.new(full_path) # try and load the frontpage

    request.body = params.to_json
    res = http.request(request)
    if res && res.kind_of?(Net::HTTPRedirection)
      logger.debug "\n host redirected"
      host_exists?(res['location']) # Go after any redirect and make sure you can access the redirected URL 
    else
      logger.debug "\n return code #{res.code}" 
      ! %W(4 5).include?(res.code[0]) # Not from 4xx or 5xx families
    end
  rescue Errno::ENOENT
    logger.debug "\nENOENT: error"
    false #false if can't find the server
  rescue Errno::ECONNREFUSED
    logger.debug "\nECONNREFUSED: error"
    false # connection refused
  end

  private

  def self.encode_path_params(path, params)
    encoded = URI.encode_www_form(params)
    [path, encoded].join("?")
  end


end