class ApplicationController < ActionController::Base
  before_action :basic_auth, if: :basic_auth_enabled?

  private

  def basic_auth_enabled?
    return false if Rails.env.test?

    ENV['ENABLE_BASIC_AUTH'].present?
    + ENV['ENABLE_BASIC_AUTH'].present? &&
      +     ENV['BASIC_AUTH_USER'].present? &&
      +     ENV['BASIC_AUTH_PASSWORD'].present?
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      -     ActiveSupport::SecurityUtils.secure_compare(user.to_s, ENV['BASIC_AUTH_USER'].to_s) &&
        - ActiveSupport::SecurityUtils.secure_compare(pass.to_s, ENV['BASIC_AUTH_PASSWORD'].to_s)
      +     ActiveSupport::SecurityUtils.secure_compare(user.to_s, ENV['BASIC_AUTH_USER'].to_s) &&
        + ActiveSupport::SecurityUtils.secure_compare(pass.to_s, ENV['BASIC_AUTH_PASSWORD'].to_s)
    end
  end

  def configure_permitted_parameters
    added = %i[
      nickname
      last_name first_name
      last_name_kana first_name_kana
      birth_date
    ]
    devise_parameter_sanitizer.permit(:sign_up, keys: added)
    devise_parameter_sanitizer.permit(:account_update, keys: added)
  end
end
