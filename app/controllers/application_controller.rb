class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # User authentication
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  
  def logged_in?
    !!current_user
  end
  
  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please log in to continue"
    end
  end
  
  # Hotwire Native detection
  def native_app?
    request.user_agent&.match?(/Hotwire Native/)
  end
  
  helper_method :current_user, :logged_in?, :native_app?
  
  before_action :configure_turbo_native
  
  private
  
  # HTML escape helper for inline HTML generation
  def h(text)
    ERB::Util.html_escape(text.to_s)
  end
  
  def configure_turbo_native
    if native_app?
      response.headers["Turbo-Native-Bridge"] = "true"
    end
  end
end