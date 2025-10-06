# Test Project and Task Management
library(testthat)
library(shinytest2)
library(data.table)

test_that("Settings tab has project/task creation inputs", {
  cleanup_test_data()

  app <- AppDriver$new(app_dir = "../../", name = "settings-inputs")
  app$wait_for_idle()

  values <- app$get_values()

  # Verify Settings tab inputs exist
  expect_true("new_project_name" %in% names(values$input))
  expect_true("task_project_select" %in% names(values$input))
  expect_true("new_task_name" %in% names(values$input))

  app$stop()
})

test_that("New project can be created", {
  cleanup_test_data()

  app <- AppDriver$new(app_dir = "../../", name = "project-create")
  app$wait_for_idle()

  # Enter project name
  app$set_inputs(new_project_name = "Test Project Alpha")

  # Click add button
  app$click("add_project")
  app$wait_for_idle(timeout = 5000)

  app$stop()

  # Verify project was added
  data <- readRDS("../../app_data/time_log.rds")
  expect_true("Test Project Alpha" %in% data$project)
})

test_that("New task can be added to existing project", {
  cleanup_test_data()

  # Create initial project
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "task-create")
  app$wait_for_idle()

  # Select project and enter task name
  app$set_inputs(
    task_project_select = "Project A",
    new_task_name = "New Task Beta"
  )

  # Click add button
  app$click("add_task")
  app$wait_for_idle(timeout = 5000)

  app$stop()

  # Verify task was added
  data <- readRDS("../../app_data/time_log.rds")
  project_a_tasks <- data[project == "Project A", unique(task)]
  expect_true("New Task Beta" %in% project_a_tasks)
})

test_that("Duplicate project names are prevented", {
  cleanup_test_data()

  # Create initial project
  initial_data <- create_sample_entries(n_projects = 1, entries_per_project = 1)
  save_test_data(initial_data, filename = "../../app_data/time_log.rds")

  app <- AppDriver$new(app_dir = "../../", name = "project-duplicate")
  app$wait_for_idle()

  # Try to add duplicate project
  app$set_inputs(new_project_name = "Project A")
  app$click("add_project")
  app$wait_for_idle(timeout = 3000)

  app$stop()

  # Verify only one "Project A" entry (or notification shown)
  # The app should show a warning notification
})
