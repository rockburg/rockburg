require "openai"

# Set default OpenAI configuration
OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY", nil)
  config.request_timeout = 60 # Optional
  config.log_errors = true
end
