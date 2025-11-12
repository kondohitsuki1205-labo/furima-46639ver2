# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # 本番 or ENVでONのときだけBasic認証を有効化
  before_action :basic_auth, if: :basic_auth_enabled?
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    keys = %i[nickname last_name first_name last_name_kana first_name_kana birth_date]
    devise_parameter_sanitizer.permit(:sign_up,        keys: keys)
    devise_parameter_sanitizer.permit(:account_update, keys: keys)
  end

  private

  def basic_auth_enabled?
    # ✅ RSpec（test）では常にOFF
    return false if Rails.env.test?

    enabled_flag = ENV['ENABLE_BASIC_AUTH'] == 'true'
    (Rails.env.production? || enabled_flag) &&
      ENV['BASIC_AUTH_USER'].present? &&
      ENV['BASIC_AUTH_PASSWORD'].present?
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV.fetch('BASIC_AUTH_USER', '')) &&
        ActiveSupport::SecurityUtils.secure_compare(pass, ENV.fetch('BASIC_AUTH_PASSWORD', ''))
    end
  end
end

