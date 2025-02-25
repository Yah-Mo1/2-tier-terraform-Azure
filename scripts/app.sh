#!/bin/bash
# Install and configure application dependencies

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs

# Install PM2 process manager
sudo npm install -g pm2

# Clone the application repository
git clone https://github.com/Yah-Mo1/test-app

# Configure Nginx as a reverse proxy
sudo sed -i 's|try_files.*|proxy_pass http://127.0.0.1:3000;|' /etc/nginx/sites-available/default
sudo systemctl reload nginx

# Set up database connection
export DB_HOST=mongodb://<db_private_ip>:27017/posts

# Install application dependencies and seed the database
cd test-app
npm install

# Start the application with PM2
pm2 start app.js