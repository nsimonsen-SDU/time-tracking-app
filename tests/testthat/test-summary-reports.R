# Test Summary and Reports
library(testthat)
library(shinytest2)
library(data.table)

test_that("Summary tab displays current week hours", {
  cleanup_test_data()

  # Create test data with entries from this week
  test_data <- create_sample_entries(n_projects = 1, entries_per_project = 2)
  save_test_data(test_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "summary-week")
  app$wait_for_idle()

  # Get output values
  values <- app$get_values(output = c("current_week_hours", "current_month_hours", "all_time_hours"))

  # Verify outputs exist and are not null
  expect_true(!is.null(values$output$current_week_hours))
  expect_true(!is.null(values$output$current_month_hours))
  expect_true(!is.null(values$output$all_time_hours))

  app$stop()
})

test_that("Summary by project table shows data", {
  cleanup_test_data()

  test_data <- create_sample_entries(n_projects = 2, entries_per_project = 3)
  save_test_data(test_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "summary-project")
  app$wait_for_idle()

  # Get summary table output
  values <- app$get_values(output = "summary_by_project")

  # Verify table exists
  expect_true(!is.null(values$output$summary_by_project))

  app$stop()
})
