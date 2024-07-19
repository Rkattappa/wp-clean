#!/bin/bash

# Define directories
NEW_CONTENT_DIR=~/wordpress-content
PUBLIC_HTML=./public_html
NEW_PLUGIN_DIR=$NEW_CONTENT_DIR/plugins
NEW_THEME_DIR=$NEW_CONTENT_DIR/themes
NEW_UPLOADS_DIR=$NEW_CONTENT_DIR/uploads

# Create new content directories if they don't exist
mkdir -p $NEW_PLUGIN_DIR $NEW_THEME_DIR $NEW_UPLOADS_DIR

# Backup wp-config.php
cp $PUBLIC_HTML/wp-config.php ~/wp-config-backup.php

# Extract DB credentials and table prefix from wp-config.php
DB_NAME=$(grep DB_NAME ~/wp-config-backup.php | cut -d "'" -f 4)
DB_USER=$(grep DB_USER ~/wp-config-backup.php | cut -d "'" -f 4)
DB_PASSWORD=$(grep DB_PASSWORD ~/wp-config-backup.php | cut -d "'" -f 4)
DB_HOST=$(grep DB_HOST ~/wp-config-backup.php | cut -d "'" -f 4)
TABLE_PREFIX=$(grep '$table_prefix' ~/wp-config-backup.php | cut -d "'" -f 2)

# Ensure wp-content directories exist in the new location
mkdir -p $PUBLIC_HTML/wp-content/plugins
mkdir -p $PUBLIC_HTML/wp-content/themes
mkdir -p $PUBLIC_HTML/wp-content/uploads

# Forcefully move existing wp-content directories to new location
mv -f $PUBLIC_HTML/wp-content/plugins/* $NEW_PLUGIN_DIR/
mv -f $PUBLIC_HTML/wp-content/themes/* $NEW_THEME_DIR/
mv -f $PUBLIC_HTML/wp-content/uploads/* $NEW_UPLOADS_DIR/

# Clean public_html
rm -rf $PUBLIC_HTML/*

# Download and install WordPress core
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
mv wordpress/* $PUBLIC_HTML/
rm -rf wordpress
rm latest.tar.gz

# Create new wp-config.php with extracted data
cat <<EOF > $PUBLIC_HTML/wp-config.php
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASSWORD', '$DB_PASSWORD');
define('DB_HOST', '$DB_HOST');
\$table_prefix  = '$TABLE_PREFIX';
define('WP_DEBUG', false);
if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
EOF

# Ensure wp-content directories exist in the public_html
mkdir -p $PUBLIC_HTML/wp-content/plugins
mkdir -p $PUBLIC_HTML/wp-content/themes
mkdir -p $PUBLIC_HTML/wp-content/uploads

# Forcefully move directories back to wp-content
mv -f $NEW_PLUGIN_DIR/* $PUBLIC_HTML/wp-content/plugins/
mv -f $NEW_THEME_DIR/* $PUBLIC_HTML/wp-content/themes/
mv -f $NEW_UPLOADS_DIR/* $PUBLIC_HTML/wp-content/uploads/

# Create .htaccess file with default WordPress rules
cat <<EOF > $PUBLIC_HTML/.htaccess
# BEGIN WordPress
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF

# Set permissions for files and directories
find $PUBLIC_HTML -type f -exec chmod 644 {} \;
find $PUBLIC_HTML -type d -exec chmod 755 {} \;

# Set permissions for public_html
chmod 755 $PUBLIC_HTML

# Set ownership
chown -R $(whoami):$(whoami) $PUBLIC_HTML

echo "WordPress core reinstalled and wp-config.php recreated with existing database information."
echo "Themes, plugins, and uploads have been moved back to wp-content."
echo ".htaccess file created with default WordPress rules."
echo "Permissions have been set for files, directories, and public_html."

# Remove the script itself
rm -- "$0"
