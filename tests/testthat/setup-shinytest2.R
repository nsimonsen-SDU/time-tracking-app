# Setup file for shinytest2 tests

# Set any environment variables or app-level configuration here
# This file is run once before all tests

# Ensure test database exists
if (!file.exists("../../app_data/credentials.sqlite")) {
  message("Creating test credentials database...")
  library(shinymanager)

  # Create credentials database for testing
  create_db(
    credentials_data = data.frame(
      user = c("admin"),
      password = c("admin123"),
      admin = c(TRUE),
      stringsAsFactors = FALSE
    ),
    sqlite_path = "../../app_data/credentials.sqlite",
    passphrase = "timetracking_secure_passphrase_2025"
  )
}
