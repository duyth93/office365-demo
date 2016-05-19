module SessionsHelper
  def require_login
    redirect_to new_sessions_path if session[:email].nil?
  end
end
