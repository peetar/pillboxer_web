# Deploying Pill Boxer to Fly.io

## Prerequisites

1. **Install Fly.io CLI:**
   ```bash
   # Windows (PowerShell)
   iwr https://fly.io/install.ps1 -useb | iex
   ```

2. **Sign up for Fly.io:**
   ```bash
   flyctl auth signup
   # Or if you have an account:
   flyctl auth login
   ```

## Deployment Steps

### 1. Initial Setup

Make the docker-entrypoint executable:
```bash
cd c:\code\pillboxer\p-boxer\web
chmod +x bin/docker-entrypoint  # Or use Git Bash
```

### 2. Launch the App

```bash
flyctl launch --no-deploy
```

This will:
- Create a new app name (or you can specify one)
- Create the fly.toml configuration
- Set up the app in your Fly.io account

When prompted:
- **App name**: Accept default or choose your own (e.g., `pillboxer`)
- **Region**: Choose closest to you (e.g., `sea` for Seattle)
- **PostgreSQL database**: Say **NO** (we're using SQLite)
- **Redis**: Say **NO**

### 3. Create Volume for SQLite Database

SQLite needs persistent storage:
```bash
flyctl volumes create pillboxer_data --region sea --size 1
```

### 4. Set Secrets

Generate and set a secret key:
```bash
# Generate a secret key
$secret = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | % {[char]$_})
flyctl secrets set SECRET_KEY_BASE=$secret
```

### 5. Deploy!

```bash
flyctl deploy
```

This will:
- Build your Docker image
- Push it to Fly.io
- Start your app
- Run database migrations

### 6. Open Your App

```bash
flyctl open
```

## Post-Deployment

### Create First User

Since you can't sign up yet, you'll need to create a user via console:

```bash
flyctl ssh console
cd /app
bundle exec rails console -e production
```

Then in the Rails console:
```ruby
User.create!(name: 'Your Name', username: 'yourusername', password: 'yourpassword')
exit
```

### View Logs

```bash
flyctl logs
```

### Check Status

```bash
flyctl status
```

### Scale (if needed)

```bash
# Add more memory
flyctl scale memory 512

# Add more VMs
flyctl scale count 2
```

## Updating the App

When you make changes:

```bash
flyctl deploy
```

## Useful Commands

```bash
# SSH into your app
flyctl ssh console

# Check resource usage
flyctl dashboard

# View secrets
flyctl secrets list

# Restart app
flyctl apps restart

# Destroy app (careful!)
flyctl apps destroy
```

## Troubleshooting

### Check if app is running:
```bash
flyctl status
```

### View detailed logs:
```bash
flyctl logs --follow
```

### Connect to production console:
```bash
flyctl ssh console
cd /app
bundle exec rails console -e production
```

### Database issues:
```bash
flyctl ssh console
cd /app
bundle exec rails db:migrate
```

## Cost

- Free tier includes:
  - Up to 3 shared-cpu-1x 256MB VMs
  - 3GB persistent volume storage
  - 160GB outbound data transfer

Your app should run for free with these settings!

## Android App Configuration

After deployment, update your Android app's BASE_URL:

1. Open `android/app/build.gradle`
2. Change `BASE_URL` to your Fly.io URL:
   ```gradle
   buildConfigField 'String', 'BASE_URL', '"https://pillboxer.fly.dev"'
   ```
3. Rebuild the Android app

## Domain Setup (Optional)

To use a custom domain:
```bash
flyctl certs add yourdomain.com
```

Then add the DNS records shown in the output.
