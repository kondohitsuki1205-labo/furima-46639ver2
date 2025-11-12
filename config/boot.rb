ENV['SSL_CERT_FILE'] ||= '/etc/ssl/certs/ca-certificates.crt'
ENV['SSL_CERT_DIR']  ||= '/etc/ssl/certs'

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.