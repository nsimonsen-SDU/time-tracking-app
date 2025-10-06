# Time Tracking Shiny App

A Shiny application for tracking time spent on projects and tasks with persistent timers.

## Features

- **Active Timer**: Start/stop timers with live elapsed time and long-duration confirmations (>8hrs)
- **Manual Entry**: Add time entries with date/time validation and project-specific task selection
- **Time Log**: View, filter (by date, project, task), edit, delete, and export entries
- **Summary & Reports**: Track current week/month hours with color-coded widgets
- **Settings**: Create and manage projects and tasks
- **Data Management**: CSV export, edit/delete entries with confirmation dialogs

## Installation

1. Install required R packages:
```r
Rscript install_packages.R
```

Required packages:
- shiny
- data.table
- lubridate
- DT
- shinyjs

## Running the App

From the command line:
```bash
Rscript run_app.R
```

Or in R/RStudio:
```r
shiny::runApp()
```

The app will open in your default web browser.

## Data Storage

- Time log data is stored in `app_data/time_log.rds`
- Data persists across app sessions
- Active timers are automatically restored on app restart

## Architecture

- **Data Structure**: Single `data.table` with columns for log_id, project, task, start_datetime, end_datetime, hours, notes, and entry_type
- **Timer Logic**: Based on timestamps rather than active counting, ensuring data integrity
- **Reactive Architecture**: Uses `reactiveValues()` for state management
- **Auto-save**: All changes are immediately persisted to disk

## Testing

This app uses `shinytest2` for comprehensive integration testing. The test suite covers all implemented features including timer functionality, manual entry, project/task management, data persistence, and reporting.

### Running Tests

**Run all tests:**
```r
# In R console
testthat::test_dir("tests/testthat")

# Or from command line with environment variable
NOT_CRAN=true Rscript -e "testthat::test_dir('tests/testthat')"
```

**Run specific test file:**
```r
testthat::test_file("tests/testthat/test-timer-core.R")
```

### Test Structure

- `test-timer-core.R` - Active timer functionality, start/stop, persistence, long duration confirmation
- `test-data-persistence.R` - File I/O, data structure integrity, state management
- `test-manual-entry.R` - Manual entry form validation and submission
- `test-project-task-management.R` - Project/task creation and validation
- `test-dynamic-dropdowns.R` - Project-specific task filtering (Feature #8)
- `test-summary-reports.R` - Summary statistics and aggregations
- `helper-functions.R` - Shared test utilities

### Test Coverage

**Current Status**: 29+ tests passing, covering:
- ✅ App initialization and data loading
- ✅ Timer start/stop functionality
- ✅ Data persistence across sessions
- ✅ Project and task creation
- ✅ Manual entry form submission
- ✅ Data structure validation
- ✅ Active timer persistence

### Writing New Tests

Use the `AppDriver` class from shinytest2 to interact with the app:

```r
test_that("Example test", {
  app <- AppDriver$new(app_dir = "../../", name = "test-name")
  app$wait_for_idle()

  # Set inputs
  app$set_inputs(input_id = "value")

  # Click buttons
  app$click("button_id")

  # Verify outputs
  values <- app$get_values()
  expect_true(!is.null(values$output$output_id))

  app$stop()
})
```

## Current Status

### Completed Features

**Phase 1 - Core Functionality:**
- ✅ 5-tab UI layout
- ✅ Data.table initialization and file I/O
- ✅ Reactive values setup
- ✅ Timer start/stop functionality
- ✅ Data persistence
- ✅ Active timer detection on startup

**Phase 2 - Data Entry & Management:**
- ✅ **Project creation** - Add new projects from Settings tab
- ✅ **Task creation** - Add new tasks to existing projects
- ✅ **Manual entry** - Add time entries with date/time validation
- ✅ **Dynamic task dropdowns** - Project-specific task selection
- ✅ Automatic validation (no duplicates, non-empty names, time format)
- ✅ Reactive dropdown updates

**Phase 3 - Data Management & Validation:**
- ✅ **Edit entries** - Modal dialog with full entry editing
- ✅ **Delete entries** - Confirmation dialog before permanent deletion
- ✅ **Long duration confirmation** - Prevent accidental timer stops (>8 hours)
- ✅ Data.table by-reference updates
- ✅ Comprehensive validation

**Phase 4 - Enhanced Reporting:**
- ✅ **CSV export** - Download filtered time logs
- ✅ **Task filtering** - Filter by project and task
- ✅ **Weekly/Monthly summaries** - Current week, month, and all-time hours
- ✅ Summary reports by project, task, and day
- ✅ Custom date range filtering

### Coming Soon
- Excel export with formatting (Phase 5)
- Data import (Phase 5)
- Visualizations and charts (Phase 4)
- Overlap detection (Phase 3)
- Project color coding (Phase 5)

See [docs/TODO.md](docs/TODO.md) for the complete feature roadmap.
