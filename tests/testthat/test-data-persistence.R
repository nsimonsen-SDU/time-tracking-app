# Test Data Persistence and File I/O
library(testthat)
library(shinytest2)
library(data.table)

test_that("App starts with empty data when no file exists", {
  cleanup_test_data()

  app <- AppDriver$new(app_dir = "../../", name = "data-empty")
  app$wait_for_idle()

  # App should load successfully
  values <- app$get_values()
  expect_true(!is.null(values))

  app$stop()

  # Data file should be created
  expect_true(file.exists("app_data/time_log.rds"))
})

test_that("Data file is created on first run", {
  cleanup_test_data()

  # Verify file doesn't exist
  expect_false(file.exists("app_data/time_log.rds"))

  # Start app
  app <- AppDriver$new(app_dir = "../../", name = "data-create")
  app$wait_for_idle()
  app$stop()

  # File should now exist
  expect_true(file.exists("app_data/time_log.rds"))

  # Load and verify structure
  data <- readRDS("app_data/time_log.rds")
  expect_s3_class(data, "data.table")
  expect_true("log_id" %in% names(data))
  expect_true("project" %in% names(data))
  expect_true("task" %in% names(data))
  expect_true("start_datetime" %in% names(data))
  expect_true("end_datetime" %in% names(data))
  expect_true("hours" %in% names(data))
  expect_true("notes" %in% names(data))
  expect_true("entry_type" %in% names(data))
})

test_that("App loads existing data on startup", {
  cleanup_test_data()

  # Create test data
  test_data <- create_sample_entries(n_projects = 2, entries_per_project = 2)
  save_test_data(test_data)

  # Start app
  app <- AppDriver$new(app_dir = "../../", name = "data-load")
  app$wait_for_idle()
  app$stop()

  # Data should still exist and have same number of rows
  loaded_data <- readRDS("app_data/time_log.rds")
  expect_equal(nrow(loaded_data), 4)  # 2 projects * 2 entries each
})

test_that("Data persists after app operations", {
  cleanup_test_data()

  # Create initial data
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data)

  # Get initial count
  initial_count <- nrow(initial_data)

  # Start app and perform operation (add project)
  app <- AppDriver$new(app_dir = "../../", name = "data-persist")
  app$wait_for_idle()

  # Add a new project
  app$set_inputs(new_project_name = "Test Project")
  app$click("add_project")
  app$wait_for_idle(timeout = 3000)

  app$stop()

  # Load data and verify it changed
  final_data <- readRDS("app_data/time_log.rds")
  expect_true(nrow(final_data) > initial_count)
})

test_that("Active timer persists across sessions", {
  cleanup_test_data()

  # Create a long-running timer
  timer_data <- create_long_timer(hours_ago = 2)
  save_test_data(timer_data)

  # Start first session
  app1 <- AppDriver$new(app_dir = "../../", name = "timer-persist-1")
  app1$wait_for_idle()

  # Verify timer is active
  values1 <- app1$get_values(output = "timer_status_display")
  expect_true(grepl("Timer Running|Long Running Project", values1$output$timer_status_display$html))

  app1$stop()

  # Verify data still has active timer
  data_between <- readRDS("app_data/time_log.rds")
  active_between <- data_between[is.na(end_datetime)]
  expect_equal(nrow(active_between), 1)

  # Start second session
  app2 <- AppDriver$new(app_dir = "../../", name = "timer-persist-2")
  app2$wait_for_idle()

  # Verify timer is still active
  values2 <- app2$get_values(output = "timer_status_display")
  expect_true(grepl("Timer Running|Long Running Project", values2$output$timer_status_display$html))

  app2$stop()
})

test_that("Data.table structure is maintained", {
  cleanup_test_data()

  # Create data
  test_data <- create_sample_entries(n_projects = 2, entries_per_project = 3)
  save_test_data(test_data)

  # Load through app
  app <- AppDriver$new(app_dir = "../../", name = "data-structure")
  app$wait_for_idle()
  app$stop()

  # Reload and verify
  loaded_data <- readRDS("app_data/time_log.rds")

  # Check it's a data.table
  expect_s3_class(loaded_data, "data.table")

  # Check key is set
  expect_equal(key(loaded_data), "log_id")

  # Check all required columns exist
  required_cols <- c("log_id", "project", "task", "start_datetime",
                    "end_datetime", "hours", "notes", "entry_type")
  expect_true(all(required_cols %in% names(loaded_data)))

  # Check data types
  expect_type(loaded_data$log_id, "integer")
  expect_type(loaded_data$project, "character")
  expect_type(loaded_data$task, "character")
  expect_s3_class(loaded_data$start_datetime, "POSIXct")
  expect_s3_class(loaded_data$end_datetime, "POSIXct")
  expect_type(loaded_data$hours, "double")
  expect_type(loaded_data$notes, "character")
  expect_type(loaded_data$entry_type, "character")
})
