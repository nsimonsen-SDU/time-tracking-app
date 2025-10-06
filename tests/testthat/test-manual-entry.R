# Test Manual Entry Functionality
library(testthat)
library(shinytest2)
library(data.table)

test_that("Manual entry form exists and has required inputs", {
  cleanup_test_data()

  app <- AppDriver$new(app_dir = "../../", name = "manual-form")
  app$wait_for_idle()

  # Get input values
  values <- app$get_values()

  # Verify manual entry inputs exist
  expect_true("manual_project" %in% names(values$input))
  expect_true("manual_task" %in% names(values$input))
  expect_true("manual_start_date" %in% names(values$input))
  expect_true("manual_start_time" %in% names(values$input))
  expect_true("manual_end_date" %in% names(values$input))
  expect_true("manual_end_time" %in% names(values$input))
  expect_true("manual_notes" %in% names(values$input))

  app$stop()
})

test_that("Manual entry can submit with valid data", {
  cleanup_test_data()

  # Create initial project/task
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "manual-submit")
  app$wait_for_idle()

  # Fill in manual entry form
  app$set_inputs(
    manual_project = "Project A",
    manual_task = "Task A 1",
    manual_start_time = "09:00",
    manual_end_time = "12:00"
  )

  # Submit
  app$click("submit_manual")
  app$wait_for_idle(timeout = 5000)

  app$stop()

  # Verify entry was created
  data <- readRDS("../../app_data/time_log.rds")
  expect_true(nrow(data) > 1)  # Should have more than initial entry
})
