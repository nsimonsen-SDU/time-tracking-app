# Setup script to create initial credentials database
# Run this once to initialize the authentication system

library(shinymanager)

# Create credentials database
create_db(
  credentials_data = data.frame(
    user = c("admin"),
    password = c("admin123"),  # Change this password after first login!
    admin = c(TRUE),
    stringsAsFactors = FALSE
  ),
  sqlite_path = "app_data/credentials.sqlite",
  passphrase = "timetracking_secure_passphrase_2025"  # Change this to a secure passphrase
)

cat("\n==============================================\n")
cat("Credentials database created successfully!\n")
cat("==============================================\n\n")
cat("Default credentials:\n")
cat("  Username: admin\n")
cat("  Password: admin123\n\n")
cat("IMPORTANT: Change the default password after first login!\n\n")
cat("Database location: app_data/credentials.sqlite\n")
cat("==============================================\n\n")
