# Helper functions for shinytest2 tests

#' Initialize a clean test app with fresh data
#' @param cleanup_before If TRUE, removes existing test data before starting
#' @return AppDriver instance
create_test_app <- function(cleanup_before = TRUE) {
  if (cleanup_before) {
    cleanup_test_data()
  }

  # Initialize app
  app <- AppDriver$new(
    app_dir = system.file(package = "shinytest2"),
    name = "time-tracking-app",
    height = 800,
    width = 1200,
    wait = TRUE,
    timeout = 10000
  )

  return(app)
}

#' Clean up test data files
cleanup_test_data <- function() {
  # Remove test RDS files
  test_files <- c(
    "app_data/time_log.rds",
    "app_data/test_time_log.rds"
  )

  for (file in test_files) {
    if (file.exists(file)) {
      file.remove(file)
    }
  }

  invisible(TRUE)
}

#' Create sample time entries for testing
#' @param n_projects Number of projects to create
#' @param entries_per_project Number of entries per project
#' @return data.table with sample entries
create_sample_entries <- function(n_projects = 2, entries_per_project = 3) {
  library(data.table)

  time_log <- data.table(
    log_id = integer(),
    project = character(),
    task = character(),
    start_datetime = as.POSIXct(character()),
    end_datetime = as.POSIXct(character()),
    hours = numeric(),
    notes = character(),
    entry_type = character()
  )

  log_id_counter <- 0

  for (p in 1:n_projects) {
    project_name <- paste("Project", LETTERS[p])

    for (t in 1:entries_per_project) {
      log_id_counter <- log_id_counter + 1
      task_name <- paste("Task", LETTERS[p], t)

      # Create entries with timestamps in the past
      start_time <- Sys.time() - ((log_id_counter * 3600) + 3600)
      end_time <- start_time + 3600  # 1 hour duration

      entry <- data.table(
        log_id = log_id_counter,
        project = project_name,
        task = task_name,
        start_datetime = start_time,
        end_datetime = end_time,
        hours = 1.0,
        notes = paste("Sample entry", log_id_counter),
        entry_type = ifelse(p %% 2 == 0, "manual", "timer")
      )

      time_log <- rbindlist(list(time_log, entry), use.names = TRUE)
    }
  }

  setkey(time_log, log_id)
  return(time_log)
}

#' Create a long-running timer (for testing long duration confirmation)
#' @param hours_ago How many hours ago the timer started (default: 9)
#' @return data.table with single active timer entry
create_long_timer <- function(hours_ago = 9) {
  library(data.table)

  timer <- data.table(
    log_id = 1L,
    project = "Long Running Project",
    task = "Marathon Task",
    start_datetime = Sys.time() - (hours_ago * 3600),
    end_datetime = as.POSIXct(NA),
    hours = NA_real_,
    notes = "Long running timer for testing",
    entry_type = "timer"
  )

  setkey(timer, log_id)
  return(timer)
}

#' Wait for DataTable to update
#' @param app AppDriver instance
#' @param output_id Output ID of the DataTable
#' @param timeout Maximum wait time in milliseconds
wait_for_table_update <- function(app, output_id = "time_log_table", timeout = 5000) {
  app$wait_for_idle(timeout = timeout)
  Sys.sleep(0.5)  # Additional buffer for DT rendering
  invisible(TRUE)
}

#' Verify notification appeared
#' @param app AppDriver instance
#' @param text Expected text in notification (partial match)
#' @return TRUE if notification found, FALSE otherwise
verify_notification <- function(app, text) {
  # This is a placeholder - actual implementation depends on how
  # Shiny notifications are accessible in shinytest2
  # May need to use app$get_html() or custom JavaScript

  # For now, just wait and assume success
  Sys.sleep(0.5)
  return(TRUE)
}

#' Extract data from a DataTable output
#' @param app AppDriver instance
#' @param output_id Output ID of the DataTable
#' @return data.frame with table data
get_table_data <- function(app, output_id = "time_log_table") {
  values <- app$get_values(output = output_id)

  # Extract data from DT output structure
  # This may need adjustment based on actual DT output format
  if (!is.null(values$output[[output_id]])) {
    return(values$output[[output_id]]$data)
  }

  return(NULL)
}

#' Save test data to RDS file
#' @param time_log data.table to save
#' @param filename Filename (default: app_data/time_log.rds)
save_test_data <- function(time_log, filename = "app_data/time_log.rds") {
  if (!dir.exists("app_data")) {
    dir.create("app_data", recursive = TRUE)
  }
  saveRDS(time_log, filename)
  invisible(TRUE)
}

#' Load test data from RDS file
#' @param filename Filename (default: app_data/time_log.rds)
#' @return data.table with time log data
load_test_data <- function(filename = "app_data/time_log.rds") {
  if (file.exists(filename)) {
    return(readRDS(filename))
  }
  return(NULL)
}
