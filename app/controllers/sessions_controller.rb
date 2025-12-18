class SessionsController < ApplicationController
  def new
    # Render inline HTML with Turbo support
    html = generate_login_html_with_turbo
    render html: html.html_safe
  end

  def create
    email = params[:email]&.downcase
    password = params[:password]
    
    user = User.authenticate(email, password)
    
    if user
      session[:user_id] = user.id
      user.update(last_login_at: Time.current)
      redirect_to root_path, notice: "Welcome back, #{user.name}!"
    else
      html = generate_login_html("Invalid email or password")
      render html: html.html_safe
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Logged out successfully"
  end

  private
  
  def generate_login_html_with_turbo
    csrf_token = form_authenticity_token
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Login - Pill Boxer</title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <meta name="turbo-visit-control" content="reload">
        <script type="module">
          import * as Turbo from "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.12/+esm";
        </script>
        <style>
          body { font-family: system-ui, -apple-system, sans-serif; margin: 0; background: #f5f5f5; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
          .container { max-width: 400px; width: 100%; margin: 20px; }
          .card { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
          .header { text-align: center; margin-bottom: 30px; }
          .form-group { margin-bottom: 20px; }
          .form-group label { display: block; margin-bottom: 5px; font-weight: 500; color: #333; }
          .form-group input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; box-sizing: border-box; }
          .btn { width: 100%; background: #007AFF; color: white; padding: 12px; border: none; border-radius: 4px; font-size: 16px; cursor: pointer; margin-bottom: 16px; }
          .links { text-align: center; }
          .links a { color: #007AFF; text-decoration: none; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="card">
            <div class="header">
              <h1>💊 Pill Boxer</h1>
              <p>Sign in to your account</p>
            </div>
            
            <form method="post" action="/login">
              <input type="hidden" name="authenticity_token" value="#{csrf_token}">
              <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" required>
              </div>
              
              <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
              </div>
              
              <button type="submit" class="btn">Sign In</button>
            </form>
            
            <div class="links">
              <p>Don't have an account? <a href="/signup">Sign up here</a></p>
            </div>
          </div>
        </div>
      </body>
      </html>
    HTML
  end

  def generate_login_html(error_message = nil)
    csrf_token = form_authenticity_token
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Login - Pill Boxer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="icon" type="image/png" href="/pb-icon-large.png">
        <style>
          body { font-family: system-ui, -apple-system, sans-serif; margin: 0; background: #f5f5f5; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
          .container { max-width: 400px; width: 100%; margin: 20px; }
          .card { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
          .header { text-align: center; margin-bottom: 30px; }
          .header img { width: 64px; height: 64px; border-radius: 8px; margin-bottom: 16px; }
          .form-group { margin-bottom: 20px; }
          .form-group label { display: block; margin-bottom: 5px; font-weight: 500; color: #333; }
          .form-group input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; box-sizing: border-box; }
          .form-group input:focus { outline: none; border-color: #007AFF; }
          .btn { width: 100%; background: #007AFF; color: white; padding: 12px; border: none; border-radius: 4px; font-size: 16px; cursor: pointer; margin-bottom: 16px; }
          .btn:hover { background: #0056d3; }
          .error { background: #fee; color: #c33; padding: 10px; border-radius: 4px; margin-bottom: 16px; text-align: center; }
          .links { text-align: center; }
          .links a { color: #007AFF; text-decoration: none; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="card">
            <div class="header">
              <img src="/pb-icon-large.png" alt="Pill Boxer">
              <h1>Welcome Back</h1>
              <p>Sign in to your Pill Boxer account</p>
            </div>
            
            #{error_message ? "<div class=\"error\">#{error_message}</div>" : ""}
            
            <form method="post" action="/login">
              <input type="hidden" name="authenticity_token" value="#{csrf_token}">
              <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" required>
              </div>
              
              <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required>
              </div>
              
              <button type="submit" class="btn">Sign In</button>
            </form>
            
            <div class="links">
              <p>Don't have an account? <a href="/signup">Sign up here</a></p>
            </div>
          </div>
        </div>
      </body>
      </html>
    HTML
  end
end