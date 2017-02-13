class Assistant < ActiveRecord::Base
  attr_accessible :enabled, :uri, :name
  has_many :labs

  validates_presence_of :name, :uri
  validates_uniqueness_of :uri

  def get_lab(params={})
		result = self.get_request("/api/v1/lab", params)
		#logger.debug result
    result
	end

	def create_labuser(params={})
		result = self.post_request("/api/v1/labuser", params)
		logger.debug result
    result
	end

	 ###   #### API CALLS ####  ### 
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
			params.merge!({:api_key=> self.token }) 
		end
		uri = URI.parse(self.uri)
		http = Net::HTTP.new(uri.host, uri.port)
		http.read_timeout = 500 # seconds  
		if self.uri.starts_with?('https://')
			http.use_ssl = true
			if Rails.env == 'development'
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: IMPORTANT!! read into this
			end
		end
			
		verbs = {
			:get    => Net::HTTP::Get,
			:post   => Net::HTTP::Post,
			:put    => Net::HTTP::Put,
			:delete => Net::HTTP::Delete
		}
		request = verbs[method.to_sym].new(path, {'Content-Type' =>'application/json'})
		request.body = params.to_json
		http.request(request)
	end

	# assistant responds with 200
  def host_exists?(url_string = '', redirects = 0)
    url = URI.parse( url_string=='' ? self.uri : url_string )
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 10 # seconds  
    if self.uri.starts_with?('https://')
      http.use_ssl = true
      if Rails.env == 'development'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TODO: IMPORTANT!! read into this
      end
    end
    path = "/"
    params={:auth_token=> self.token } # always add admin token

    full_path = encode_path_params(path, params)
    request = Net::HTTP::Get.new(full_path) # try and load the front page

    request.body = params.to_json
    res = http.request(request)
    if res && res.kind_of?(Net::HTTPRedirection)
      logger.debug "\n host redirected  #{self.uri} #{redirects} times"
      if redirects<5
        host_exists?(res['location'], redirects+1 ) # Go after any redirect and make sure you can access the redirected URL 
      else
        logger.error "\n host redirected too many times #{self.uri} (#{redirects} times)"
        false
      end
    else
      logger.error "\n return code #{res.code} #{self.uri}" 
      ! %W(4 5).include?(res.code[0]) # Not from 4xx or 5xx families
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
