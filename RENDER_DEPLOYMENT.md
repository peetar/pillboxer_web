# Deploying Pill Boxer to Render

## Why Render?

- ✅ Free tier includes persistent disk (1GB)
- ✅ Automatic deployments from Git
- ✅ Native SQLite support with persistent volumes
- ✅ Easy to use web dashboard
- ✅ Automatic SSL certificates

## Prerequisites

1. **GitHub Account** - You'll deploy from a Git repository
2. **Render Account** - Sign up at https://render.com (free)

## Step 1: Push Code to GitHub

If you haven't already:

```powershell
cd c:\code\pillboxer\p-boxer\web

# Initialize git if needed
git init

# Add files
git add .
git commit -m "Initial commit for Render deployment"

# Create a new repository on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/pillboxer.git
git branch -M main
git push -u origin main
```

## Step 2: Deploy on Render

### Option A: Blueprint (Recommended - Easiest)

1. Go to https://render.com/dashboard
2. Click **"New +"** → **"Blueprint"**
3. Connect your GitHub repository
4. Render will automatically detect `render.yaml`
5. Click **"Apply"**
6. That's it! Render will:
   - Create a web service
   - Create a 1GB persistent disk for SQLite
   - Build and deploy your app

### Option B: Manual Setup

1. Go to https://render.com/dashboard
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository
4. Configure:
   - **Name**: `pillboxer`
   - **Region**: Choose closest to you
   - **Branch**: `main`
   - **Runtime**: `Ruby`
   - **Build Command**: `./bin/render-build.sh`
   - **Start Command**: `bundle exec puma -C config/puma.rb`
   - **Plan**: Free

5. **Add Environment Variables**:
   - `RAILS_ENV` = `production`
   - `RAILS_LOG_TO_STDOUT` = `true`
   - `RAILS_SERVE_STATIC_FILES` = `true`
   - `SECRET_KEY_BASE` = (click "Generate" button)

6. **Add Persistent Disk**:
   - Click **"Add Disk"**
   - **Name**: `pillboxer-db`
   - **Mount Path**: `/opt/render/project/src/db`
   - **Size**: 1 GB

7. Click **"Create Web Service"**

## Step 3: Wait for Deployment

Render will:
1. Clone your repository
2. Install Ruby and dependencies
3. Run migrations
4. Start your app

This takes about 5-10 minutes. Watch the logs in real-time!

## Step 4: Create Your First User

Once deployed, you need to create a user via Rails console:

1. In Render dashboard, go to your service
2. Click **"Shell"** tab
3. Run these commands:

```bash
bundle exec rails console -e production
```

Then in the console:
```ruby
User.create!(name: 'Your Name', username: 'yourusername', password: 'yourpassword')
exit
```

## Step 5: Access Your App

Your app will be at: `https://pillboxer.onrender.com` (or your chosen name)

Click the URL at the top of your Render dashboard!

## Step 6: Update Android App

Update your Android app to use the new URL:

1. Open `android/app/build.gradle`
2. Find the `buildConfigField` for `BASE_URL`
3. Change it to:
   ```gradle
   buildConfigField 'String', 'BASE_URL', '"https://pillboxer.onrender.com"'
   ```
4. Rebuild: `.\gradlew assembleDebug`
5. Install: `.\gradlew installDebug`

## Automatic Deployments

Every time you push to GitHub, Render automatically redeploys! 🎉

```powershell
git add .
git commit -m "Update feature"
git push
```

Render detects the push and deploys automatically.

## Viewing Logs

1. Go to your service in Render dashboard
2. Click **"Logs"** tab
3. See real-time logs

## Important Notes

### Free Tier Limitations

- **Spins down after 15 minutes of inactivity**
  - First request after sleep takes ~30 seconds to wake up
  - Consider upgrading to paid plan ($7/month) to keep it always on

- **750 hours/month free**
  - More than enough for one service

### Database Backups

Your SQLite database is on the persistent disk. To backup:

1. Click **"Shell"** in Render dashboard
2. Run:
   ```bash
   cp db/production.sqlite3 db/backup-$(date +%Y%m%d).sqlite3
   ```

### Troubleshooting

**Build fails?**
- Check logs in Render dashboard
- Make sure `bin/render-build.sh` is executable
- Verify all gems are in Gemfile

**App crashes?**
- Check logs for errors
- Verify environment variables are set
- Check that disk is mounted to `/opt/render/project/src/db`

**Can't access?**
- Check Events tab for deployment status
- Make sure HTTPS is used (HTTP redirects to HTTPS)
- Check `config.hosts` allows `.onrender.com`

## Cost

**Free Tier:**
- 750 hours/month
- 512 MB RAM
- 1 GB persistent disk
- Automatic sleep after 15 minutes inactivity

**Paid Tier ($7/month):**
- No sleep
- 2 GB RAM
- Better performance
- Custom domains

Your app should run fine on the free tier for testing!

## Custom Domain (Optional)

To use your own domain:

1. In Render dashboard, go to your service
2. Click **"Settings"**
3. Scroll to **"Custom Domain"**
4. Add your domain
5. Update DNS records as shown

## Comparison: Render vs Fly.io

| Feature | Render | Fly.io |
|---------|--------|--------|
| Setup | Easier (GUI) | CLI-based |
| Git Integration | Built-in | Manual |
| Free Tier | 750h, sleeps | Always on |
| SQLite Support | Native disk | Volumes |
| Auto Deploy | Yes | No |
| Best For | Quick setup | More control |

Both are great! Render is easier for beginners.
