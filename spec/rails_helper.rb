require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

# PNG生成のために追加
require 'base64'
require 'fileutils'

# データベースマイグレーションの確認
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# --- ▼▼▼ ここを修正（コメントを外して有効化）▼▼▼ ---
# spec/support 以下のファイルを再帰的に読み込む (sign_in に必須)
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
# --- ▲▲▲ ここまで修正 ▲▲▲ ---

require 'devise'

RSpec.configure do |config|
  # fixtureのパス
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # ★ sign_in を機能させるために必須
  config.use_transactional_fixtures = true

  # ファイルパスからスペックのタイプを自動推論
  config.infer_spec_type_from_file_location!

  # Rails特有のバックトレースをフィルタリング
  config.filter_rails_from_backtrace!

  # FactoryBot の省略記法（create, build など）
  config.include FactoryBot::Syntax::Methods

  # Devise のリクエストスペック用ヘルパー (sign_in を提供) - これを有効化
  config.include Devise::Test::IntegrationHelpers, type: :request
  # Devise のシステムスペック用ヘルパー (これは残す)
  config.include Devise::Test::IntegrationHelpers, type: :system

  # --- 競合するため Warden 関連の記述は削除 (正しい状態) ---
  # config.include Warden::Test::Helpers

  # config.before(:suite) で設定を統合
  config.before(:suite) do
    # --- 競合するため Warden 関連の記述は削除 (正しい状態) ---
    # Warden.test_mode!

    # 2. test.png の自動生成
    dir = Rails.root.join('spec/fixtures/files')
    FileUtils.mkdir_p(dir)
    path = dir.join('test.png')
    unless File.exist?(path)
      # 1x1透明PNG（Base64）
      png_base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO0YFz0AAAAASUVORK5CYII='
      File.binwrite(path, Base64.decode64(png_base64))
    end
  end # <--- config.before(:suite) を閉じる 'end'

  # --- 競合するため Warden 関連の記述は削除 (正しい状態) ---
  # config.after(:each) { Warden.test_reset! }
end # <--- RSpec.configure を閉じる 'end'

# Shoulda Matchers の設定
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
