#!/usr/bin/env bash
# Web Static Deployment Setup Script - FIXED VERSION
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

# Update Nginx configuration - FIXED VERSION
echo "Updating Nginx configuration..."

# Create a backup of the original configuration
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Remove any existing hbnb_static configuration first
sudo sed -i '/location \/hbnb_static\//,/^[[:space:]]*}/d' /etc/nginx/sites-available/default

# Create the new Nginx configuration with proper formatting
sudo tee /etc/nginx/sites-available/default > /dev/null <<'EOF'
##
# You should look at the following URL's in order to get a solid understanding
# of Nginx configuration files in order to fully unleash the power of Nginx.
# https://www.nginx.com/resources/wiki/start/
# https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/
# https://wiki.debian.org/Nginx/DirectoryStructure
#
# In most cases, administrators will remove this file from sites-enabled/ and
# leave it as reference inside of sites-available where it will continue to be
# updated by the nginx packaging team.
#
# This file will automatically load configuration files provided by other
# applications, such as Drupal or Wordpress. These applications will be made
# available underneath a path with that package name, such as /drupal8.
#
# Please see /usr/share/doc/nginx-doc/examples/ for more detailed examples.
##

# Default server configuration
#
server {
	listen 80 default_server;
	listen [::]:80 default_server;

	# SSL configuration
	#
	# listen 443 ssl default_server;
	# listen [::]:443 ssl default_server;
	#
	# Note: You should disable gzip for SSL traffic.
	# See: https://bugs.debian.org/773332
	#
	# Read up on ssl_ciphers to ensure a secure configuration.
	# See: https://bugs.debian.org/765782
	#
	# Self signed certs generated by the ssl-cert package
	# Don't use them in a production server!
	#
	# include snippets/snakeoil.conf;

	root /var/www/html;

	# Add index.php to the list if you are using PHP
	index index.html index.htm index.nginx-debian.html;

	server_name _;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files $uri $uri/ =404;
	}

	# Custom location for hbnb_static
	location /hbnb_static/ {
		alias /data/web_static/current/;
		index index.html index.htm;
		try_files $uri $uri/ =404;
	}

	# pass PHP scripts to FastCGI server
	#
	#location ~ \.php$ {
	#	include snippets/fastcgi-php.conf;
	#
	#	# With php-fpm (or other unix sockets):
	#	fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
	#	# With php-cgi (or other tcp sockets):
	#	fastcgi_pass 127.0.0.1:9000;
	#}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	#location ~ /\.ht {
	#	deny all;
	#}
}


# Virtual Host configuration for example.com
#
# You can move that to a different file under sites-available/ and symlink that
# to sites-enabled/ to enable it.
#
#server {
#	listen 80;
#	listen [::]:80;
#
#	server_name example.com;
#
#	root /var/www/example.com;
#	index index.html;
#
#	location / {
#		try_files $uri $uri/ =404;
#	}
#}
EOF

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
    if sudo systemctl restart nginx; then
        echo "Nginx restarted successfully"
    else
        echo "Error: Nginx restart failed"
        exit 1
    fi
    
    # Enable Nginx to start on boot
    if sudo systemctl enable nginx; then
        echo "Nginx enabled to start on boot"
    else
        echo "Warning: Could not enable Nginx on boot"
    fi
    
    # Verify Nginx is running
    if sudo systemctl is-active --quiet nginx; then
        echo "Nginx is running successfully"
    else
        echo "Error: Nginx is not running properly"
        sudo systemctl status nginx --no-pager -l || true
        exit 1
    fi
elif command -v service &> /dev/null; then
    # upstart/sysvinit (Ubuntu 14.04 and earlier)
    if sudo service nginx restart; then
        echo "Nginx restarted successfully"
    else
        echo "Error: Nginx restart failed"
        exit 1
    fi
    
    # Enable Nginx to start on boot (Ubuntu 14.04 style)
    if sudo update-rc.d nginx enable &>/dev/null; then
        echo "Nginx enabled to start on boot"
    else
        echo "Warning: Could not enable Nginx on boot, but it may already be enabled"
    fi
    
    # Verify Nginx is running
    if sudo service nginx status | grep -q "running"; then
        echo "Nginx is running successfully"
    else
        echo "Error: Nginx is not running properly"
        sudo service nginx status || true
        exit 1
    fi
else
    echo "Error: Could not determine how to restart Nginx (no systemctl or service command found)"
    exit 1
fi

# Set proper permissions for web directory
echo "Setting proper permissions..."
sudo chmod -R 755 /data/web_static/

# Verify the setup
echo "Verifying setup..."
echo "Checking if symbolic link exists:"
ls -la /data/web_static/current

echo "Checking if index.html exists:"
ls -la /data/web_static/current/index.html

echo "Checking Nginx configuration:"
sudo nginx -t

# Display setup summary
echo ""
echo "=================================="
echo "Web Static Setup Complete!"
echo "=================================="
echo "✓ Nginx installed and configured"
echo "✓ Directory structure created:"
echo "    /data/web_static/releases/test/"
echo "    /data/web_static/shared/"
echo "    /data/web_static/current/ -> /data/web_static/releases/test/"
echo "✓ Test HTML file created"
echo "✓ Nginx configuration updated with proper location block"
echo "✓ Nginx restarted and running"
echo ""
echo "You can test the deployment by visiting:"
echo "  http://localhost/hbnb_static/"
echo "  http://your-server-ip/hbnb_static/"
echo ""
echo "If you're still getting 404 errors, try these debugging commands:"
echo "  sudo nginx -t"
echo "  curl -I http://localhost/hbnb_static/"
echo "  ls -la /data/web_static/current/"
echo "  cat /etc/nginx/sites-available/default | grep -A 5 hbnb_static"

exit 0
