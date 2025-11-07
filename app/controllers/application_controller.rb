class ApplicationController < ActionController::Base
  # 本番 or ENVでONのときだけBasic認証を有効化
  before_action :basic_auth, if: :basic_auth_enabled?

  private

  def basic_auth_enabled?
    enabled_flag = ENV["ENABLE_BASIC_AUTH"] == "true"
    (Rails.env.production? || enabled_flag) &&
      ENV["BASIC_AUTH_USER"].present? &&
      ENV["BASIC_AUTH_PASSWORD"].present?
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV["BASIC_AUTH_USER"]) &
        ActiveSupport::SecurityUtils.secure_compare(pass, ENV["BASIC_AUTH_PASSWORD"])
    end
  end
end