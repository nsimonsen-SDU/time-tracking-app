# Time Tracking Shiny App

A Shiny application for tracking time spent on projects and tasks with persistent timers.

## Features

- **Active Timer**: Start/stop timers for projects and tasks with live elapsed time
- **Manual Entry**: Add time entries manually with date/time validation
- **Time Log**: View, filter (by date, project, task), and export time entries
- **Summary & Reports**: Track current week/month hours and analyze historical data
- **Settings**: Create and manage projects and tasks
- **CSV Export**: Download filtered time logs for external analysis

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
- ✅ Automatic validation (no duplicates, non-empty names, time format)
- ✅ Reactive dropdown updates

**Phase 4 - Enhanced Reporting:**
- ✅ **CSV export** - Download filtered time logs
- ✅ **Task filtering** - Filter by project and task
- ✅ **Weekly/Monthly summaries** - Current week, month, and all-time hours
- ✅ Summary reports by project, task, and day
- ✅ Custom date range filtering

### Coming Soon
- Edit/delete functionality for time entries (Phase 3)
- Excel export with formatting (Phase 5)
- Data import (Phase 5)
- Visualizations and charts (Phase 4)
- Dynamic task dropdowns based on project (Phase 2)

See [docs/TODO.md](docs/TODO.md) for the complete feature roadmap.
