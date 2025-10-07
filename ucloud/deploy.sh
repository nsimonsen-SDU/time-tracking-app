#!/bin/bash
#
# UCloud Deployment Script for Time Tracking Shiny App
# This script installs system dependencies and R packages required for the app
#
# Usage: bash ucloud/deploy.sh
#

set -e  # Exit on error

echo "=========================================="
echo "Time Tracking App - UCloud Deployment"
echo "=========================================="
echo ""

echo "Step 1: Updating package lists..."
sudo apt-get update -qq

echo ""
echo "Step 2: Installing system dependencies..."
echo "This may take a few minutes..."
echo ""

# Install system libraries required for R packages
sudo apt-get install -y -qq \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    libsodium-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev

echo "✓ System dependencies installed successfully"
echo ""

echo "Step 3: Installing R packages..."
echo "This will take several minutes, please be patient..."
echo ""

# Run the R package installation script as current user
Rscript install_packages.R

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ R packages installed successfully"
else
    echo ""
    echo "✗ Error installing R packages"
    exit 1
fi

echo ""
echo "Step 4: Setting up credentials database..."

# Check if credentials database already exists
if [ -f "app_data/credentials.sqlite" ]; then
    echo "✓ Using existing credentials database"
else
    Rscript setup_credentials.R
    echo "✓ Credentials database created"
fi

echo ""
echo "Step 5: Setting permissions..."

# Ensure the app directory has proper permissions for shiny-server
# Using sudo for chown, but running as current user preserves ownership
sudo chown -R "$USER:$USER" .
chmod -R 755 .
chmod 700 app_data/credentials.sqlite 2>/dev/null || true

echo "✓ Permissions set"
echo ""

echo "=========================================="
echo "✓ Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure shiny-server to serve this app"
echo "2. Default login credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "⚠️  IMPORTANT: Change the default password after first login!"
echo ""
echo "To start the app manually for testing:"
echo "   Rscript run_app.R"
echo ""
echo "For shiny-server deployment, ensure your config points to:"
echo "   $(pwd)"
echo ""
