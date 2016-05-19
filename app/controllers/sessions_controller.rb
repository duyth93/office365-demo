class SessionsController < ApplicationController
  before_action :load_office365_service, except: [:new, :index]
  before_action :find_user
  skip_before_action :verify_authenticity_token

  def index
  end

  def new
  end

  def create
    redirect_to @office365_service.get_login_url sessions_callback_url
  end

  def update
    @token = @user.access_token if @office365_service.renew_token @user
    render :index
  end

  def destroy
    reset_session
    redirect_to @office365_service.get_logout_url root_url
  end

  def callback
    unless @office365_service.store_access_token params
      flash[:error] = "Something went wrong ..."
    end
    session[:email] = @office365_service.email
    redirect_to root_url
  end

  def send_mail
    @message = @office365_service.send_mail(params, session, @user) ? "Send mail successfully" : "Send mail failed"
    render :index
  end

  private
  def load_office365_service
    @office365_service = Office365Service.new
  end

  def find_user
    @user = User.find_by email: session[:email]
  end
end
