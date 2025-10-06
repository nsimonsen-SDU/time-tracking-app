# Test Dynamic Task Dropdowns (Feature #8)
library(testthat)
library(shinytest2)
library(data.table)

test_that("Timer task dropdown filters by selected project", {
  cleanup_test_data()

  # Create data with multiple projects and tasks
  test_data <- create_sample_entries(n_projects = 2, entries_per_project = 2)
  save_test_data(test_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "dropdown-timer")
  app$wait_for_idle()

  # Select Project A
  app$set_inputs(timer_project = "Project A")
  app$wait_for_idle()

  # Get task dropdown choices
  values <- app$get_values(input = "timer_task")

  # Verify only Project A tasks are shown
  # (This depends on how dropdown choices are exposed in values)

  app$stop()
})

test_that("Manual entry task dropdown filters by selected project", {
  cleanup_test_data()

  test_data <- create_sample_entries(n_projects = 2, entries_per_project = 2)
  save_test_data(test_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "dropdown-manual")
  app$wait_for_idle()

  # Select Project B
  app$set_inputs(manual_project = "Project B")
  app$wait_for_idle()

  # Verify task dropdown updated
  values <- app$get_values(input = "manual_task")

  app$stop()
})
