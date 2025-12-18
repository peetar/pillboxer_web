source 'https://rubygems.org'
ruby '3.4.7'

gem 'rails', '~> 7.1.0'
gem 'hotwire-rails'
gem 'sqlite3', '~> 1.4' # SQLite for development
gem 'puma', '~> 6.0' # Web server
gem 'sass-rails', '>= 6' # For CSS preprocessing
gem 'image_processing', '~> 1.2' # For image variants
gem 'turbo-rails' # For Turbo support
gem 'stimulus-rails' # For Stimulus support
gem 'jbuilder' # Build JSON APIs
gem 'bootsnap', '>= 1.4.4', require: false # Reduces boot times
gem 'bcrypt', '~> 3.1.7', require: 'bcrypt' # For secure password hashing - explicitly require

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development, :test do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ] # Debugging tool
  gem 'rspec-rails' # Testing framework
end

group :development do
  gem 'web-console', '>= 4.1.0' # Console on exceptions pages
  gem 'listen', '~> 3.3' # File watcher
  gem 'spring' # Speed up development
end

group :production do
  gem 'pg', '~> 1.1' # PostgreSQL for production
end