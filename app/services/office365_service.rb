class Office365Service
  attr_accessor :email

  CLIENT_CRED = ADAL::ClientCredential.new(
    ENV["CLIENT_ID"], ENV["CLIENT_SECRET"])

  def initialize
  end

  def get_login_url callback_url
    "#{Settings.office_365_api.AUTHORIZE_ENDPOINT}?client_id=#{ENV["CLIENT_ID"]}\
      &redirect_uri=#{ERB::Util.url_encode callback_url}\
      &response_mode=form_post&response_type=code+id_token&nonce=#{nonce}"
  end

  def get_logout_url target_url
    "#{Settings.office_365_api.LOGOUT_ENDPOINT}?post_logout_redirect_uri=#{ERB::Util.url_encode target_url}"
  end

  def store_access_token params
    # authorize code, use this to get access token
    auth_code = params["code"]
    user_info = get_user_info_from_id_token params["id_token"]
    @email = user_info[:email]
    response = request_access_token auth_code, Settings.office_365_api.REPLY_URL
    if response.class.name == Settings.office_365_api.ADAL_SUCCESS
      return create_or_update_user response, user_info[:email], user_info[:name]
    end
    false
  end

  def renew_token user
    auth_context = ADAL::AuthenticationContext.new(
      Settings.office_365_api.CONTEXT_PATH, Settings.office_365_api.TENANT)
    response = auth_context.acquire_token_with_refresh_token user.refresh_token,
      CLIENT_CRED, Settings.office_365_api.GRAPH_RESOURCE
    if response.class.name == Settings.office_365_api.ADAL_SUCCESS
      return user.update_attributes access_token: response.access_token,
        expires_on: response.expires_on, refresh_token: response.refresh_token
    end
    false
  end

  private
  def nonce
    SecureRandom.uuid
  end

  def request_access_token auth_code, reply_url
    auth_context = ADAL::AuthenticationContext.new(
      Settings.office_365_api.CONTEXT_PATH, Settings.office_365_api.TENANT)
    auth_context.acquire_token_with_authorization_code auth_code, reply_url,
      CLIENT_CRED, Settings.office_365_api.GRAPH_RESOURCE
  end

  # get user info code from jwt
  def get_user_info_from_id_token id_token
    token_parts = id_token.split(".")
    encoded_token = token_parts[1]
    leftovers = token_parts[1].length.modulo(4)
    if leftovers == 2
      encoded_token << "=="
    elsif leftovers == 3
      encoded_token << "="
    end
    decoded_token = Base64.urlsafe_decode64(encoded_token)
    jwt = JSON.parse decoded_token
    {email: jwt["unique_name"], name: jwt["name"]}
  end

  def create_or_update_user response, email, name
    params = {access_token: response.access_token, refresh_token: response.refresh_token,
      account_type: :office365, expires_on: response.expires_on, name: name, email: email}
    user = User.find_by email: email
    return user.update_attributes params if user
    user = User.new params
    user.save
  end
end
