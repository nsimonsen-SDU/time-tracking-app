# Time Tracking Shiny App

A Shiny application for tracking time spent on projects and tasks with persistent timers.

## Features

- **Active Timer**: Start/stop timers for projects and tasks
- **Manual Entry**: Add time entries manually with date/time pickers
- **Time Log**: View, filter, and search all time entries
- **Summary & Reports**: Analyze time spent by project, task, or day
- **Settings**: Manage projects and tasks

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

Run the test suite to verify functionality:
```bash
# Test syntax
Rscript test_app.R

# Test data I/O
Rscript test_data_io.R
```

## Current Status

Basic structure is complete with:
- ✅ 5-tab UI layout
- ✅ Data.table initialization and file I/O
- ✅ Reactive values setup
- ✅ Timer start/stop functionality
- ✅ Data persistence
- ✅ Active timer detection on startup

Coming soon:
- Manual entry form submission
- Edit/delete functionality
- Project and task management
- Data export features
