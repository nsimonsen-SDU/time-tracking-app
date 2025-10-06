# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Shiny application for tracking time spent on projects and tasks with persistent timers. Timer logic is based on start/end timestamps rather than active counting, ensuring data integrity even when the app is closed.

## Architecture

### Data Structure
- Single tidy `data.table` as the core data structure
- Stored as RDS/CSV in `app_data/time_log.rds`
- Columns: `log_id`, `project`, `task`, `start_datetime`, `end_datetime`, `hours`, `notes`, `entry_type`
- Key on `log_id` for fast lookups
- Active timers identified by `is.na(end_datetime)`

### Core Modules
1. **Timer Module**: Start/stop timer functionality with only one active timer allowed at a time
2. **Manual Entry Module**: Form-based time entry with validation
3. **Project & Task Management**: Dynamic project/task creation and management
4. **Data Display & Reporting**: Filtering, aggregations, and summaries using data.table
5. **Settings/Management**: Configuration and data import/export

### Data Persistence
- Use `readRDS()`/`saveRDS()` for data.table preservation
- Alternative: `fread()`/`fwrite()` for CSV with POSIXct conversion
- Save on every timer start/stop and manual entry
- On app start, check for active timer: `time_log[is.na(end_datetime)]`

### Key Technical Patterns

**data.table Operations:**
- Update by reference with `:=` to avoid copying
- Fast aggregations: `time_log[, .(total = sum(hours)), by = project]`
- Filtering: `time_log[start_datetime >= date_from & start_datetime <= date_to]`
- Set keys for frequently filtered columns

**Reactive Architecture:**
- `reactiveValues()` for active timer state and time_log data.table
- `invalidateLater(1000)` for updating elapsed time display
- `observe()` for auto-save operations

**Time Handling:**
- Store timestamps in UTC
- Use `lubridate` for time operations
- Calculate hours: `as.numeric(difftime(end_datetime, start_datetime, units = "hours"))`

**Validation:**
- Prevent multiple active timers: `nrow(time_log[is.na(end_datetime)]) > 0`
- Ensure `end_datetime > start_datetime`
- Validate inputs before saving

## UI Structure
Five-tab layout: Active Timer | Manual Entry | Time Log | Summary & Reports | Settings/Management

## Development Phases
1. Core timer functionality (start/stop, data storage)
2. Manual entry and project/task management
3. Data display and filtering
4. Summary reports and visualizations
5. UI polish and validation
6. Optional enhancements