Rails.application.configure do
  # Hotwire Native configuration
  config.hotwire_native = ActiveSupport::OrderedOptions.new
  
  # Configure Hotwire Native bridge
  config.hotwire_native.enabled = true
  
  # Path matching for native app requests
  config.hotwire_native.user_agent_pattern = /Hotwire Native/
end