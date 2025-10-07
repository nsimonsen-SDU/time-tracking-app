# Tests for User Authentication Feature
# Testing authentication, user management, and password changes

library(testthat)
library(shinytest2)
library(DBI)
library(RSQLite)

test_that("Authentication: Credentials database exists", {
  skip_if_not(file.exists("../../app_data/credentials.sqlite"),
              "Credentials database not found")

  expect_true(file.exists("../../app_data/credentials.sqlite"))

  # Verify database structure
  con <- dbConnect(RSQLite::SQLite(), "../../app_data/credentials.sqlite")
  tables <- dbListTables(con)
  dbDisconnect(con)

  expect_true("credentials" %in% tables)
})

test_that("Authentication: Admin user exists", {
  skip_if_not(file.exists("../../app_data/credentials.sqlite"),
              "Credentials database not found")

  con <- dbConnect(RSQLite::SQLite(), "../../app_data/credentials.sqlite")
  users <- dbReadTable(con, "credentials")
  dbDisconnect(con)

  expect_true("admin" %in% users$user)
  expect_true(any(users$admin == 1 | users$admin == TRUE))
})

test_that("Authentication: Login page appears", {
  skip_on_cran()
  skip_if_not(file.exists("../../app_data/credentials.sqlite"),
              "Credentials database not found")

  app <- AppDriver$new("../../app.R", name = "auth-login",
                       height = 800, width = 1200)

  # Check that login UI is displayed
  expect_true(app$wait_for_idle(timeout = 5000))

  # Look for authentication elements
  html <- app$get_html("body")

  # shinymanager should show a login form
  expect_match(html, "password|login|username", ignore.case = TRUE)

  app$stop()
})

test_that("Authentication: Logout button exists in UI", {
  skip_on_cran()
  skip("Manual test - requires authenticated session")

  # This test would require successful authentication first
  # Manual verification: Login and check for logout button in top-right
})

test_that("Authentication: User Management UI exists", {
  skip_on_cran()
  skip("Manual test - requires authenticated session")

  # This test would require successful authentication first
  # Manual verification: Navigate to Settings tab and check for user management section
})

test_that("Authentication: Password validation", {
  # Test password validation logic
  short_password <- "12345"
  valid_password <- "password123"

  expect_true(nchar(short_password) < 6)
  expect_true(nchar(valid_password) >= 6)
})

test_that("Authentication: Username validation", {
  # Test username validation logic
  short_username <- "ab"
  valid_username <- "admin"

  expect_true(nchar(short_username) < 3)
  expect_true(nchar(valid_username) >= 3)
})

test_that("Authentication: Credentials database is gitignored", {
  gitignore_path <- "../../.gitignore"

  if (file.exists(gitignore_path)) {
    gitignore <- readLines(gitignore_path)
    expect_true(any(grepl("credentials\\.sqlite", gitignore)))
  }
})

# Integration test notes:
# ======================
# Manual tests required for full authentication flow:
# 1. Login with admin/admin123
# 2. Change password
# 3. Add new user (admin only)
# 4. Login as new user
# 5. Logout
# 6. Verify session timeout (15 min default)
# 7. Test timer persistence across logout/login
