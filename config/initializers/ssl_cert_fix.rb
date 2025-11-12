# OSの正しい証明書ファイルのパス
ca_file_path = '/etc/ssl/certs/ca-certificates.crt'

# 1. RubyのOpenSSLライブラリのデフォルトパスを上書き
#    (環境設定が効かないため、ここで強制的に指定)
OpenSSL::SSL::DEFAULT_CERT_FILE = ca_file_path
OpenSSL::SSL::DEFAULT_CERT_DIR = '/etc/ssl/certs'

# 2. 'payjp' gem 自身に、使用する証明書ファイルを明示的に設定
#    (これが payjp gem への正しい設定方法です)
begin
  require 'payjp'
  Payjp.ssl_ca_file = ca_file_path
rescue LoadError
  # (Rails起動時には通常問題なくロードされるはず)
end