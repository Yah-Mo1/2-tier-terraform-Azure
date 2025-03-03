#!/bin/bash
# This script deploys a Node.js app on Ubuntu 22.04
 
# Exit script if error occurs
set -e
 
# Set debconf to non-interactive mode to bypass prompts
export DEBIAN_FRONTEND=noninteractive
 
# Log all output (both stdout & stderr) to a log file and display in terminal
exec > >(tee -a /var/log/prov-app.log) 2>&1
 
echo "🔄 Updating package list and upgrading packages..."
sudo apt update && sudo apt upgrade -y
 
echo "🌐 Installing Nginx..."
sudo apt install -y nginx
 
# Enable & Start Nginx if not already running
if ! systemctl is-active --quiet nginx; then
  echo "✅ Enabling & starting Nginx..."
  sudo systemctl enable nginx
  sudo systemctl start nginx
else
  echo "✅ Nginx is already running."
fi
 
echo "📦 Installing Node.js & npm..."
sudo bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
sudo apt-get install -y nodejs git
 
echo "⚙️ Installing PM2..."
if ! command -v pm2 &> /dev/null; then
  sudo npm install -g pm2
else
  echo "✅ PM2 is already installed."
fi
 
echo "📂 Checking for Node.js app repo..."
APP_DIR="/home/ubuntu/tech501-sparta-app"
 
if [ -d "$APP_DIR" ]; then
  echo "🔄 Repo exists, pulling latest changes..."
  cd "$APP_DIR"
  git reset --hard
  git pull
else
  echo "📥 Cloning the Node.js app repo..."
  git clone https://github.com/Yah-Mo1/test-app "$APP_DIR"
fi
 
echo "🛠️ Configuring Nginx Reverse Proxy..."
NGINX_CONF="/etc/nginx/sites-available/default"
if ! grep -q "proxy_pass http://127.0.0.1:3000;" "$NGINX_CONF"; then
  sudo sed -i 's|try_files.*|proxy_pass http://127.0.0.1:3000;|' "$NGINX_CONF"
else
  echo "✅ Nginx reverse proxy already configured."
fi
 
echo "🔄 Restarting Nginx to apply changes..."
sudo systemctl restart nginx
 
echo "🗄️ Setting up MongoDB connection..."
export DB_HOST="mongodb://<db_private_ip>:27017/posts"
 
echo "📂 Changing directory to app..."
cd "$APP_DIR/app"
 
echo "📦 Installing npm dependencies..."
npm install
 
# Set HOME variable for PM2
export HOME=/home/ubuntu
 
echo "🚀 Starting Node.js app with PM2..."
if pm2 describe app > /dev/null 2>&1; then
  echo "🔄 Restarting existing app..."
  pm2 restart app --update-env
else
  echo "✅ Starting new instance of the app..."
  pm2 start app.js --name app --env production --update-env
fi
 
# Ensure PM2 auto-starts on reboot
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save
 
echo "🎉 Deployment successful!"