#!/usr/bin/env bash
# Web Static Deployment Setup Script (Simplified)
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
sudo mkdir -p /data/web_static/releases/test/
sudo mkdir -p /data/web_static/shared/

# Create fake HTML file for testing
echo "Creating test HTML file..."
sudo tee /data/web_static/releases/test/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Static Test Page</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .status { background-color: #d4edda; padding: 10px; border-radius: 5px; margin: 20px 0; }
        ul { margin: 20px 0; }
        li { margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Web Static Deployment Test</h1>
        <div class="status">
            <strong>Status:</strong> Nginx configuration is working correctly!
        </div>
        <p>This is a test page for the web_static deployment setup.</p>
        <p>If you can see this page, it means:</p>
        <ul>
            <li>Nginx is properly installed and running</li>
            <li>The directory structure has been created correctly</li>
            <li>The symbolic link is working</li>
            <li>The Nginx configuration is serving static content</li>
        </ul>
        <p><strong>Path:</strong> /data/web_static/current/index.html</p>
        <p><strong>Timestamp:</strong> $(date)</p>
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
if id "ubuntu" &>/dev/null; then
    echo "Ubuntu user exists, setting ownership to ubuntu:ubuntu"
    sudo chown -R ubuntu:ubuntu /data/
else
    echo "Ubuntu user does not exist, checking for other suitable users..."
    # Try to find a suitable non-root user
    if id "www-data" &>/dev/null; then
        echo "Using www-data user for ownership"
        sudo chown -R www-data:www-data /data/
    elif [ -n "$SUDO_USER" ] && id "$SUDO_USER" &>/dev/null; then
        echo "Using sudo user ($SUDO_USER) for ownership"
        sudo chown -R "$SUDO_USER:$SUDO_USER" /data/
    else
        echo "Warning: No suitable user found, keeping root ownership"
        echo "You may need to manually set ownership later"
    fi
fi

# Update Nginx configuration using a simpler approach
echo "Updating Nginx configuration..."

# Check if the configuration already exists in default site
if ! sudo grep -q "location /hbnb_static" /etc/nginx/sites-available/default; then
    echo "Adding hbnb_static location block to Nginx configuration..."
    
    # Create a backup of the original configuration
    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    
    # Create the nginx location block configuration
    sudo tee /tmp/hbnb_static_location > /dev/null <<'NGINX_CONFIG'
        location /hbnb_static {
                alias /data/web_static/current;
                index index.html index.htm;
        }
NGINX_CONFIG
    
    # Insert the location block before the last closing brace of the server block
    # This is a more reliable approach than complex awk
    sudo sed -i '/server {/,/^}$/ {
        /^}$/ i\
        location /hbnb_static {\
                alias /data/web_static/current;\
                index index.html index.htm;\
        }
    }' /etc/nginx/sites-available/default
    
    # Clean up temp file
    sudo rm -f /tmp/hbnb_static_location
else
    echo "hbnb_static location block already exists in Nginx configuration"
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "Nginx configuration test passed"
else
    echo "Nginx configuration test failed. Restoring backup..."
    if [ -f /etc/nginx/sites-available/default.backup ]; then
        sudo cp /etc/nginx/sites-available/default.backup /etc/nginx/sites-available/default
        echo "Backup restored. Please check the configuration manually."
    fi
    exit 1
fi

# Detect init system and restart Nginx accordingly
echo "Restarting Nginx..."
if command -v systemctl &> /dev/null; then
    # systemd (Ubuntu 15.04+)
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    echo "Nginx restarted and enabled (systemd)"
elif command -v service &> /dev/null; then
    # upstart/sysvinit (Ubuntu 14.04 and earlier)
    sudo service nginx restart
    sudo update-rc.d nginx enable &>/dev/null || true
    echo "Nginx restarted and enabled (upstart/sysvinit)"
else
    echo "Error: Could not determine how to restart Nginx"
    exit 1
fi

# Set proper permissions for web directory
echo "Setting proper permissions..."
sudo chmod -R 755 /data/web_static/

# Verify the setup
echo ""
echo "=== VERIFICATION ==="
echo "Directory structure:"
ls -la /data/web_static/ 2>/dev/null || echo "Could not list directory"
echo ""
echo "Symbolic link:"
ls -la /data/web_static/current 2>/dev/null || echo "Could not check symbolic link"
echo ""
echo "Test file:"
ls -la /data/web_static/current/index.html 2>/dev/null || echo "Could not find test file"
echo ""
echo "Nginx hbnb_static configuration:"
sudo grep -A 3 -B 1 "location.*hbnb_static" /etc/nginx/sites-available/default || echo "No hbnb_static configuration found"
echo ""

# Display setup summary
echo "=================================="
echo "Web Static Setup Complete!"
echo "=================================="
echo "✓ Nginx installed and configured"
echo "✓ Directory structure created"
echo "✓ Test HTML file created"
echo "✓ Symbolic link created"
echo "✓ Nginx configuration updated"
echo "✓ Nginx restarted"
echo ""
echo "Test URLs:"
echo "  http://localhost/hbnb_static"
echo "  http://localhost/hbnb_static/"
echo ""

exit 0
