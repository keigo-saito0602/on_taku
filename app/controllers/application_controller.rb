class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  before_action :require_login

  add_flash_types :success, :warning

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login
    return if current_user.present?

    redirect_to new_session_path, alert: "ログインしてください"
  end

  def require_organizer!
    return if current_user&.organizer?

    redirect_to root_path, alert: "操作権限がありません"
  end
end
