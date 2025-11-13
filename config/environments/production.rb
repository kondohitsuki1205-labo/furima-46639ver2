# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available…
  # config.require_master_key = true

  # Serve static files from /public on Render
  config.public_file_server.enabled = true

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"

  # ---------- Active Storage ----------
  # 本番はとりあえずローカル（恒久対応はS3推奨）
  config.active_storage.service = :local

  # /rails/active_storage/disk/... の期限付きURLではなく、
  # Railsプロキシ経由で配信させ、期限切れ404を避ける
  config.active_storage.resolve_model_to_route = :rails_storage_proxy
  # -----------------------------------

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume SSL is terminated at the proxy and force SSL in Rails.
  # config.assume_ssl = true
  config.force_ssl = true

  # Log to STDOUT by default (Render)
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Log level
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Active Job
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "furima_46639ver2_production"

  config.action_mailer.perform_caching = false

  # I18n fallbacks
  config.i18n.fallbacks = true

  # Deprecations
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Host protection
  # config.hosts = []
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # ここで default_url_options を安全にセット（APP_HOST 未設定時は Render のホスト）
  config.after_initialize do
    host = ENV.fetch("APP_HOST", "furima-46639.onrender.com")
    Rails.application.routes.default_url_options[:host]     = host
    Rails.application.routes.default_url_options[:protocol] = "https"
  end
end
