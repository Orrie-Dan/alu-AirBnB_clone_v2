#!/usr/bin/env bash
# Web Static Deployment Setup Script
# This script sets up web servers for the deployment of web_static

set -e  # Exit on any error

echo "Starting web_static deployment setup..."

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Install Nginx if not already installed
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt-get install -y nginx
else
    echo "Nginx is already installed"
fi

# Create directory structure
echo "Creating directory structure..."

# Create /data/ if it doesn't exist
sudo mkdir -p /data/

# Create /data/web_static/ if it doesn't exist
sudo mkdir -p /data/web_static/

# Create /data/web_static/releases/ if it doesn't exist
sudo mkdir -p /data/web_static/releases/

# Create /data/web_static/shared/ if it doesn't exist
sudo mkdir -p /data/web_static/shared/

# Create /data/web_static/releases/test/ if it doesn't exist
sudo mkdir -p /data/web_static/releases/test/

# Create fake HTML file for testing
echo "Creating test HTML file..."
sudo tee /data/web_static/releases/test/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Static Test Page</title>
    </head>
<body>
    <div class="container">
        <h1>Web Static Deployment Test</h1>
        <div class="status">
            <strong>Status:</strong> Nginx configuration is working correctly!
        </div>
        <p>This is a test page for the web_static deployment setup.</p>
    </div>
</body>
</html>
EOF

# Handle symbolic link
echo "Setting up symbolic link..."
# Remove existing symbolic link if it exists
if [ -L /data/web_static/current ]; then
    echo "Removing existing symbolic link..."
    sudo rm /data/web_static/current
fi

# Create new symbolic link
sudo ln -sf /data/web_static/releases/test/ /data/web_static/current

# Set ownership recursively to ubuntu user and group
echo "Setting ownership to ubuntu user and group..."
sudo chown -R ubuntu:ubuntu /data/

# Update Nginx configuration
echo "Updating Nginx configuration..."

# Create the configuration block for hbnb_static
NGINX_CONFIG="	location /hbnb_static/ {
		alias /data/web_static/current/;
		index index.html index.htm;
		try_files \$uri \$uri/ =404;
	}"

# Check if the configuration already exists in default site
if ! sudo grep -q "location /hbnb_static/" /etc/nginx/sites-available/default; then
    echo "Adding hbnb_static location block to Nginx configuration..."
    
    # Create a temporary file with the new configuration
    sudo cp /etc/nginx/sites-available/default /tmp/nginx_default_backup
    
    # Add the location block before the closing brace of the server block
    sudo sed -i '/server {/,/}/ s/}/'"$(echo "$NGINX_CONFIG" | sed 's/[[\.*^$()+?{|]/\\&/g')"'\
}/' /etc/nginx/sites-available/default
else
    echo "hbnb_static location block already exists in Nginx configuration"
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "Nginx configuration test passed"
else
    echo "Nginx configuration test failed. Restoring backup..."
    sudo cp /tmp/nginx_default_backup /etc/nginx/sites-available/default
    exit 1
fi

# Restart Nginx to apply changes
echo "Restarting Nginx..."
sudo systemctl restart nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx

# Verify Nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "Nginx is running successfully"
else
    echo "Warning: Nginx may not be running properly"
    sudo systemctl status nginx
fi

# Display setup summary
echo ""
echo "=================================="
echo "Web Static Setup Complete!"
echo "=================================="
echo "✓ Nginx installed and configured"
echo "✓ Directory structure created:"

