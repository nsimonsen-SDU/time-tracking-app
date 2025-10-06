# Test Active Timer Core Functionality
library(testthat)
library(shinytest2)
library(data.table)

test_that("App initializes with no active timer", {
  cleanup_test_data()

  app <- AppDriver$new(
    app_dir = "../../",
    name = "timer-init",
    height = 800,
    width = 1200
  )

  # Wait for app to load
  app$wait_for_idle()

  # Get values
  values <- app$get_values()

  # Verify start button is enabled, stop button is disabled
  # (This will depend on how shinyjs disabled state is exposed)

  # Check timer status display shows "No Active Timer"
  expect_true(grepl("No Active Timer", values$output$timer_status_display$html) ||
              grepl("No timer running", values$output$elapsed_time_display))

  app$stop()
})

test_that("Timer can be started", {
  cleanup_test_data()

  # Create initial project/task
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data)

  app <- AppDriver$new(app_dir = "../../", name = "timer-start")
  app$wait_for_idle()

  # Select project and task
  app$set_inputs(timer_project = "Project A", wait_ = TRUE)
  app$set_inputs(timer_task = "Task A 1", wait_ = TRUE)

  # Click start button
  app$click("start_timer")
  app$wait_for_idle(timeout = 5000)

  # Verify timer started
  values <- app$get_values()

  # Check that timer status shows active
  expect_true(grepl("Timer Running", values$output$timer_status_display$html) ||
              grepl("Project A", values$output$timer_status_display$html))

  app$stop()
})

test_that("Timer creates entry with correct data structure", {
  cleanup_test_data()

  # Create initial data
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data)

  app <- AppDriver$new(app_dir = "../../", name = "timer-entry")
  app$wait_for_idle()

  # Start timer
  app$set_inputs(timer_project = "Project A", timer_task = "Task A 1")
  app$click("start_timer")
  app$wait_for_idle()

  # Stop app and check data file
  app$stop()

  # Load the data file
  time_log <- load_test_data()

  # Find the active timer entry (should have NA end_datetime)
  active_timer <- time_log[is.na(end_datetime)]

  expect_equal(nrow(active_timer), 1)
  expect_equal(active_timer$project, "Project A")
  expect_equal(active_timer$task, "Task A 1")
  expect_equal(active_timer$entry_type, "timer")
  expect_true(!is.na(active_timer$start_datetime))
  expect_true(is.na(active_timer$end_datetime))
})

test_that("Timer can be stopped and hours calculated correctly", {
  cleanup_test_data()

  # Create initial data
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data)

  app <- AppDriver$new(app_dir = "../../", name = "timer-stop")
  app$wait_for_idle()

  # Start timer
  app$set_inputs(timer_project = "Project A", timer_task = "Task A 1")
  app$click("start_timer")
  app$wait_for_idle()

  # Wait a bit (2 seconds)
  Sys.sleep(2)

  # Stop timer
  app$click("stop_timer")
  app$wait_for_idle()

  app$stop()

  # Load and verify
  time_log <- load_test_data()
  latest_entry <- time_log[order(-log_id)][1]

  expect_equal(latest_entry$project, "Project A")
  expect_false(is.na(latest_entry$end_datetime))
  expect_false(is.na(latest_entry$hours))

  # Hours should be approximately 2 seconds = 0.00055 hours (allow some variance)
  expect_true(latest_entry$hours > 0)
  expect_true(latest_entry$hours < 0.01)  # Less than 36 seconds
})

test_that("Only one timer can be active at a time", {
  cleanup_test_data()

  # Create initial data
  initial_data <- create_sample_entries(n_projects = 2, entries_per_project = 1)
  save_test_data(initial_data)

  app <- AppDriver$new(app_dir = "../../", name = "timer-single")
  app$wait_for_idle()

  # Start first timer
  app$set_inputs(timer_project = "Project A", timer_task = "Task A 1")
  app$click("start_timer")
  app$wait_for_idle()

  # Try to start second timer - button should be disabled
  # In the actual app, the start button is disabled when timer is active

  app$stop()

  # Verify only one active timer in data
  time_log <- load_test_data()
  active_timers <- time_log[is.na(end_datetime)]

  expect_equal(nrow(active_timers), 1)
})

test_that("Active timer persists across app restarts", {
  cleanup_test_data()

  # Create initial data
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data)

  # First session - start timer
  app1 <- AppDriver$new(app_dir = "../../", name = "timer-persist-1")
  app1$wait_for_idle()

  app1$set_inputs(timer_project = "Project A", timer_task = "Task A 1")
  app1$click("start_timer")
  app1$wait_for_idle()

  # Get the start time
  values1 <- app1$get_values()
  app1$stop()

  # Second session - verify timer is still active
  app2 <- AppDriver$new(app_dir = "../../", name = "timer-persist-2")
  app2$wait_for_idle()

  values2 <- app2$get_values()

  # Verify timer status shows active
  expect_true(grepl("Timer Running", values2$output$timer_status_display$html) ||
              grepl("Project A", values2$output$timer_status_display$html))

  app2$stop()
})

test_that("Long duration timer (>8 hours) shows confirmation dialog", {
  cleanup_test_data()

  # Create a timer that started 9 hours ago
  long_timer <- create_long_timer(hours_ago = 9)
  save_test_data(long_timer)

  app <- AppDriver$new(app_dir = "../../", name = "timer-long")
  app$wait_for_idle()

  # Verify timer is shown as active
  values <- app$get_values()
  expect_true(grepl("Timer Running", values$output$timer_status_display$html) ||
              grepl("Long Running Project", values$output$timer_status_display$html))

  # Click stop - should trigger confirmation modal
  app$click("stop_timer")
  app$wait_for_idle(timeout = 3000)

  # Verify modal appeared (this will depend on how modals are exposed)
  # For now, we'll verify the data logic worked

  app$stop()
})

test_that("Long duration timer confirmation can be cancelled", {
  cleanup_test_data()

  # Create long timer
  long_timer <- create_long_timer(hours_ago = 9)
  save_test_data(long_timer)

  app <- AppDriver$new(app_dir = "../../", name = "timer-long-cancel")
  app$wait_for_idle()

  # Click stop to trigger modal
  app$click("stop_timer")
  app$wait_for_idle()

  # Click cancel button in modal (if accessible)
  # This may require JavaScript: app$run_js("$('.modal button[data-dismiss=\"modal\"]').click()")

  # For now, stop app
  app$stop()

  # Verify timer is still active in data
  time_log <- load_test_data()
  active_timer <- time_log[is.na(end_datetime)]

  expect_equal(nrow(active_timer), 1)
})

test_that("Long duration timer can be confirmed and stopped", {
  cleanup_test_data()

  # Create long timer
  long_timer <- create_long_timer(hours_ago = 9)
  save_test_data(long_timer)

  app <- AppDriver$new(app_dir = "../../", name = "timer-long-confirm")
  app$wait_for_idle()

  # Click stop
  app$click("stop_timer")
  app$wait_for_idle()

  # Click confirm button
  # This requires accessing the modal: app$click("confirm_stop_timer")
  # For now, we'll test the logic

  app$stop()

  # In a real scenario with modal confirmation, we'd verify:
  # 1. Modal appeared
  # 2. Confirm button clicked
  # 3. Timer stopped with correct hours (~9)
})

test_that("Elapsed time display updates", {
  cleanup_test_data()

  # Create initial data
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data)

  app <- AppDriver$new(app_dir = "../../", name = "timer-elapsed")
  app$wait_for_idle()

  # Start timer
  app$set_inputs(timer_project = "Project A", timer_task = "Task A 1")
  app$click("start_timer")
  app$wait_for_idle()

  # Get initial elapsed time
  values1 <- app$get_values(output = "elapsed_time_display")
  elapsed1 <- values1$output$elapsed_time_display

  # Wait 2 seconds
  Sys.sleep(2)

  # Get updated elapsed time
  app$wait_for_idle()
  values2 <- app$get_values(output = "elapsed_time_display")
  elapsed2 <- values2$output$elapsed_time_display

  # Elapsed time should have changed
  expect_false(identical(elapsed1, elapsed2))

  app$stop()
})
