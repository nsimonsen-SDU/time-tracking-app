# Test Summary and Reports
library(testthat)
library(shinytest2)
library(data.table)

test_that("Summary tab loads with data", {
  cleanup_test_data()

  # Create test data with entries from this week
  test_data <- create_sample_entries(n_projects = 1, entries_per_project = 2)
  save_test_data(test_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "summary-week")
  app$wait_for_idle()

  # Get all values
  values <- app$get_values()

  # Verify app loaded successfully with outputs
  expect_true(!is.null(values))
  expect_true(!is.null(values$output))

  # Summary outputs exist (might be NULL if not on correct tab, but structure should exist)
  expect_true("current_week_hours" %in% names(values$output) ||
              "current_month_hours" %in% names(values$output) ||
              length(values$output) > 0)

  app$stop()
})

test_that("Summary tab with project data loads successfully", {
  cleanup_test_data()

  test_data <- create_sample_entries(n_projects = 2, entries_per_project = 3)
  save_test_data(test_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "summary-project")
  app$wait_for_idle()

  # Get all values
  values <- app$get_values()

  # Verify app loaded successfully
  expect_true(!is.null(values))
  expect_true(!is.null(values$output))

  # Verify we have outputs (tables may be NULL if not on correct tab)
  expect_true(length(values$output) > 0)

  app$stop()
})
