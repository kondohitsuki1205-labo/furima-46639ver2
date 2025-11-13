require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'devise'

# PNG生成に使用
require 'base64'
require 'fileutils'

# pending migration の検出
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# spec/support を再帰的に読み込む（Deviseの追加ヘルパ等がある場合に必須）
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # fixture の場所（単数）
  config.fixture_path = Rails.root.join('spec/fixtures').to_s

  # DBをトランザクションで巻く（Requestでも安定運用）
  config.use_transactional_fixtures = true

  # ファイルパスから spec type を自動推論（model/request/system等）
  config.infer_spec_type_from_file_location!

  # Rails 由来のバックトレースを非表示
  config.filter_rails_from_backtrace!

  # FactoryBot の省略記法（build/create等）
  config.include FactoryBot::Syntax::Methods

  # Devise ヘルパー：Request/System で sign_in を使う
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Suite 前に1x1 PNGを用意（画像必須Factory向け）
  config.before(:suite) do
    dir = Rails.root.join('spec/fixtures/files')
    FileUtils.mkdir_p(dir)
    path = dir.join('test.png')
    unless File.exist?(path)
      # 1x1透明PNG（Base64）
      png_base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO0YFz0AAAAASUVORK5CYII='
      File.binwrite(path, Base64.decode64(png_base64))
    end
  end
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
