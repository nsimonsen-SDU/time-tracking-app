# UCloud Deployment Guide

This directory contains deployment scripts and configuration for running the Time Tracking App on UCloud production servers with shiny-server.

## Prerequisites

- UCloud server with Ubuntu/Debian
- Shiny-server installed
- Root/sudo access for initial setup
- R version 4.0 or higher

## Quick Deployment

### 1. Upload App to Server

```bash
# On your local machine, from the project root
scp -r . username@ucloud-server:/path/to/shiny/apps/time-tracking-app/
```

Or clone from git:
```bash
# On the server
cd /srv/shiny-server/  # or your shiny-server app directory
git clone https://github.com/nsimonsen-SDU/time-tracking-app.git
cd time-tracking-app
```

### 2. Run Deployment Script

```bash
# On the server, in the app directory
# Script uses sudo internally for system packages
bash ucloud/deploy.sh
```

This script will:
1. ✅ Update system package lists
2. ✅ Install required system dependencies (libssl, libcurl, libsqlite3, etc.)
3. ✅ Install all required R packages
4. ✅ Create credentials database with default admin user (if not exists)
5. ✅ Set proper file permissions

**Note:** The script is fully automated and requires no user interaction. If a credentials database already exists, it will be preserved.

### 3. Configure Shiny-Server

Add this to your `/etc/shiny-server/shiny-server.conf`:

```conf
# Time Tracking App
location /time-tracking {
  app_dir /srv/shiny-server/time-tracking-app;
  log_dir /var/log/shiny-server;

  # Increase timeout for authentication
  app_idle_timeout 600;

  # Run as specific user (optional)
  # run_as username;
}
```

### 4. Restart Shiny-Server

```bash
sudo systemctl restart shiny-server
```

### 5. Access the App

Navigate to: `https://your-ucloud-server.example.com/time-tracking`

**Default Login:**
- Username: `admin`
- Password: `admin123`

⚠️ **IMPORTANT:** Change the default password immediately after first login!

## Manual Installation

If you prefer manual installation or need to troubleshoot:

### Install System Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
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
```

### Install R Packages

```bash
Rscript install_packages.R
```

### Create Credentials Database

```bash
Rscript setup_credentials.R
```

### Set Permissions

```bash
chmod -R 755 .
chmod 700 app_data/credentials.sqlite
```

## System Requirements

### Minimum Server Specs
- **CPU:** 2 cores
- **RAM:** 2GB
- **Disk:** 500MB for app + packages
- **OS:** Ubuntu 20.04+ or Debian 10+

### Required System Libraries
- libssl-dev (for encryption)
- libcurl4-openssl-dev (for HTTP requests)
- libxml2-dev (for XML parsing)
- libsqlite3-dev (for database)
- libsodium-dev (for password hashing)
- Font libraries (for plots/charts)

### Required R Packages
- shiny
- data.table
- lubridate
- DT
- shinyjs
- shinymanager
- scrypt
- testthat (dev)
- shinytest2 (dev)

## Troubleshooting

### Issue: R packages fail to install

**Solution:** Check system dependencies
```bash
# Verify all system libraries are installed
dpkg -l | grep -E "libssl-dev|libcurl|libxml2|libsqlite3"
```

### Issue: Permission denied errors

**Solution:** Fix permissions
```bash
sudo chown -R shiny:shiny /srv/shiny-server/time-tracking-app
sudo chmod -R 755 /srv/shiny-server/time-tracking-app
sudo chmod 700 /srv/shiny-server/time-tracking-app/app_data/credentials.sqlite
```

### Issue: App won't start in shiny-server

**Solution:** Check logs
```bash
sudo tail -f /var/log/shiny-server.log
sudo tail -f /var/log/shiny-server/time-tracking-app-*.log
```

### Issue: Login page doesn't appear

**Solution:** Verify credentials database
```bash
ls -la app_data/credentials.sqlite
Rscript -e "DBI::dbConnect(RSQLite::SQLite(), 'app_data/credentials.sqlite')"
```

If corrupted, recreate:
```bash
rm app_data/credentials.sqlite
Rscript setup_credentials.R
```

### Issue: Timeout during authentication

**Solution:** Increase timeout in shiny-server.conf
```conf
location /time-tracking {
  app_dir /path/to/time-tracking-app;
  app_idle_timeout 600;  # 10 minutes
  app_init_timeout 120;  # 2 minutes for startup
}
```

## Security Considerations

### Production Security Checklist

- [ ] Change default admin password
- [ ] Use strong passwords (8+ characters, symbols, numbers)
- [ ] Update the passphrase in `app.R` and `setup_credentials.R`
- [ ] Enable HTTPS on your server
- [ ] Configure firewall rules
- [ ] Regular backups of `app_data/` directory
- [ ] Keep R and packages updated
- [ ] Monitor `/var/log/shiny-server/` for suspicious activity
- [ ] Limit admin user accounts
- [ ] Set password expiration policies

### Backup Strategy

```bash
# Backup credentials and time log data
tar -czf time-tracking-backup-$(date +%Y%m%d).tar.gz \
    app_data/credentials.sqlite \
    app_data/time_log.rds

# Store backups securely off-server
scp time-tracking-backup-*.tar.gz backup-server:/backups/
```

### Update Procedure

```bash
# Pull latest changes
cd /srv/shiny-server/time-tracking-app
git pull origin master

# Reinstall packages if needed
Rscript install_packages.R

# Restart shiny-server
sudo systemctl restart shiny-server
```

## Environment Variables (Optional)

For additional security, you can use environment variables:

Create `/etc/environment` or `/etc/shiny-server/env.conf`:
```bash
TIMETRACKING_DB_PASSPHRASE="your-secure-passphrase"
TIMETRACKING_SESSION_TIMEOUT="900"  # 15 minutes
```

Then modify `app.R` to read from environment variables.

## Performance Tuning

For better performance with multiple users:

```conf
# In /etc/shiny-server/shiny-server.conf
server {
  listen 3838;

  # Increase worker processes
  utilization_scheduler 10;

  location /time-tracking {
    app_dir /srv/shiny-server/time-tracking-app;

    # Connection settings
    app_idle_timeout 600;
    app_init_timeout 120;

    # Resource limits
    simple_scheduler 5;  # Max 5 concurrent sessions
  }
}
```

## Support

For issues or questions:
- Check logs: `/var/log/shiny-server/`
- Review documentation: [AUTHENTICATION.md](../AUTHENTICATION.md)
- GitHub issues: https://github.com/nsimonsen-SDU/time-tracking-app/issues

## License

See main repository LICENSE file.
