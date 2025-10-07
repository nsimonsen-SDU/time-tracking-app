# Authentication Setup Guide

This guide explains how to use the authentication system in the Time Tracking App.

## Initial Setup

### 1. Install Required Packages

Run the installation script to install all dependencies including `shinymanager` and `scrypt`:

```r
Rscript install_packages.R
```

### 2. Create Credentials Database

Run the setup script to create the initial credentials database with a default admin user:

```r
Rscript setup_credentials.R
```

This creates `app_data/credentials.sqlite` with the following default credentials:

- **Username:** `admin`
- **Password:** `admin123`

**IMPORTANT:** Change the default password immediately after first login!

## Using the Application

### First Login

1. Start the app: `Rscript run_app.R`
2. You'll see a login page
3. Enter username: `admin` and password: `admin123`
4. Navigate to the Settings tab
5. Use the "Change Password" section to set a secure password

### Changing Your Password

1. Navigate to the **Settings** tab
2. Find the "Change Password" section
3. Enter your current password
4. Enter your new password (minimum 6 characters)
5. Confirm your new password
6. Click "Change Password"

### Logout

Click the **Logout** button in the top-right corner of the app to end your session.

## User Management (Admin Only)

Administrators can add and manage user accounts from the Settings tab.

### Adding a New User

1. Navigate to the **Settings** tab
2. Find the "Add New User" section
3. Enter a username (minimum 3 characters)
4. Enter a password (minimum 6 characters)
5. Check "Administrator privileges" if you want to grant admin rights
6. Click "Add User"

### Viewing Users

The "Existing Users" table shows all registered users with their admin status and account validity dates.

## Security Features

- **Encrypted Database:** User credentials are stored in an encrypted SQLite database
- **Hashed Passwords:** Passwords are hashed using scrypt before storage
- **Session Management:** Automatic logout after inactivity (15 minutes default)
- **Admin Controls:** Only administrators can add new users
- **Secure Passphrase:** Database encryption uses a secure passphrase

## Security Best Practices

1. **Change Default Password:** Always change the default `admin123` password
2. **Strong Passwords:** Use passwords with at least 8 characters, including numbers and symbols
3. **Protect Database:** Never commit `app_data/credentials.sqlite` to version control (it's in `.gitignore`)
4. **Change Passphrase:** For production use, change the passphrase in:
   - `setup_credentials.R`
   - `app.R` (secure_server call)
5. **Regular Updates:** Keep the shinymanager package updated
6. **Limit Admin Access:** Only grant admin privileges to trusted users

## Customization

### Session Timeout

To change the session timeout, add this to your `app.R` server function:

```r
options(shinymanager.pwd_validity = 90)  # Days until password expires
```

### Custom Login Page

Modify the `secure_app()` call in `app.R` to customize the login page:

```r
ui <- secure_app(ui,
                 theme = "flatly",           # Bootstrap theme
                 language = "en",            # Language
                 choose_language = FALSE,    # Hide language selector
                 tags_top = tags$h3("My Custom Login")  # Custom header
)
```

## Troubleshooting

### "Unable to load users" Error

If you see this error in the users table:
1. Check that `app_data/credentials.sqlite` exists
2. Verify file permissions
3. Ensure the database isn't corrupted (recreate with `setup_credentials.R`)

### "Current password is incorrect" Error

When changing password:
1. Verify you're entering the correct current password
2. Ensure caps lock is off
3. Try logging out and back in

### Login Page Not Appearing

If the app loads without authentication:
1. Verify `library(shinymanager)` is in `app.R`
2. Check that `secure_app(ui)` is called
3. Ensure `secure_server()` is in the server function

## Database Schema

The credentials database contains the following fields:

- `user`: Username (unique)
- `password`: Hashed password
- `admin`: Boolean flag for admin privileges
- `start`: Account validity start date
- `expire`: Account expiration date (NULL = no expiration)

## Future Enhancements

Currently, the authentication system provides:
- ✅ Single-user security (protects app access)
- ✅ User account management
- ✅ Password management
- ✅ Session timeout

Future enhancements (see TODO.md Feature #25):
- ❌ Multi-user data isolation (separate time logs per user)
- ❌ Shared projects and collaboration
- ❌ Role-based permissions
- ❌ Activity audit logs

## Support

For issues or questions:
1. Check the [TODO.md](docs/TODO.md) for feature status
2. Review the [CLAUDE.md](CLAUDE.md) for technical details
3. Check shinymanager documentation: https://datastorm-open.github.io/shinymanager/
