class ApplicationController < ActionController::Base
  before_action :basic_auth, if: :basic_auth_enabled?

  private

  def basic_auth_enabled?
    # テストは常にOFF。ENVでON/OFFを切り替え（devでも本番でも有効化可）
    return false if Rails.env.test?
    ENV["ENABLE_BASIC_AUTH"].present?
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      # タイミング攻撃対策で secure_compare を使用
      ActiveSupport::SecurityUtils.secure_compare(user.to_s,  ENV["BASIC_AUTH_USER"].to_s) &&
      ActiveSupport::SecurityUtils.secure_compare(pass.to_s,  ENV["BASIC_AUTH_PASSWORD"].to_s)
    end
  end
end
