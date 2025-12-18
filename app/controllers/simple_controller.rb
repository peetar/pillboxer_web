class SimpleController < ActionController::Base
  def index
    render plain: "Hello from Pill Boxer Rails App! 
    
Time: #{Time.current}
Rails: #{Rails.version}
Ruby: #{RUBY_VERSION}

This confirms Rails is working properly!"
  end
end