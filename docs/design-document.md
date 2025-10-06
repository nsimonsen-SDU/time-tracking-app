I'll revise the design document to emphasize data.table usage instead of dplyr.

## Time Tracking Shiny App - Detailed Design Document (data.table version)

### 1. App Overview & Objectives

**Purpose:** A Shiny application for tracking time spent on projects and tasks, with persistent timers that work independently of the app's running state.

**Core Philosophy:** Timer logic based on start/end timestamps rather than active counting, ensuring data integrity even when the app is closed or crashes.

### 2. Data Structure

#### 2.1 Main Time Log Table
A single tidy data.table stored as CSV/RDS with the following columns:

- `log_id`: Unique identifier for each time entry (integer or UUID)
- `project`: Project name (character)
- `task`: Task name (character)
- `start_datetime`: Start timestamp (POSIXct, stored in UTC or local timezone)
- `end_datetime`: End timestamp (POSIXct, can be NULL for active timers)
- `hours`: Calculated duration in hours (numeric, calculated from start/end)
- `notes`: Optional text field for additional context (character)
- `entry_type`: "timer" or "manual" to distinguish how the entry was created (character)

**Key for data.table:** Set key on `log_id` for fast lookups. Consider additional keys on `project` and `start_datetime` for filtering.

#### 2.2 Reference Tables (Optional, can be stored in the same file or separately)

- **Projects Table:** `project_name`, `created_date`, `active_status`
- **Tasks Table:** `project_name`, `task_name`, `created_date`

Alternatively, projects and tasks can be derived dynamically from the time log using data.table's fast unique operations.

### 3. Core Functionality Modules

#### 3.1 Timer Module

**Key Features:**
- Start a timer by selecting project and task
- Only one active timer allowed at a time
- Stop button to end the current timer
- Visual indicator showing currently running timer (project, task, elapsed time)
- Display calculated hours upon stopping

**Implementation Logic:**
- **Start Timer:** 
  - Record current timestamp as `start_datetime`
  - Set `end_datetime` to NULL/NA
  - Save immediately to persistent storage
  - Store `log_id` of active timer in reactive value
  
- **Stop Timer:**
  - Record current timestamp as `end_datetime`
  - Calculate `hours` using data.table syntax:
    ```r
    time_log[log_id == active_id, 
             `:=`(end_datetime = Sys.time(),
                  hours = as.numeric(difftime(end_datetime, start_datetime, units = "hours")))]
    ```
  - Update the record in persistent storage
  - Clear active timer indicator

- **Active Timer Detection:**
  - On app startup, check for active timer:
    ```r
    active_timer <- time_log[is.na(end_datetime)]
    ```
  - If found, set as active timer and display
  - Calculate elapsed time dynamically based on current time vs. `start_datetime`

#### 3.2 Manual Entry Module

**Key Features:**
- Form to manually add time entries
- Fields: Project, Task, Start Date/Time, End Date/Time, Notes
- Validation to ensure end time is after start time
- Automatic calculation of hours

**Implementation Logic:**
- Provide date and time pickers for start and end
- Validate inputs before saving
- Calculate hours automatically
- Add new row to data.table:
  ```r
  new_entry <- data.table(
    log_id = max(time_log$log_id, 0) + 1,
    project = input$project,
    task = input$task,
    start_datetime = input$start_datetime,
    end_datetime = input$end_datetime,
    hours = as.numeric(difftime(input$end_datetime, input$start_datetime, units = "hours")),
    notes = input$notes,
    entry_type = "manual"
  )
  time_log <- rbindlist(list(time_log, new_entry), use.names = TRUE)
  ```
- Set `entry_type` to "manual"

#### 3.3 Project & Task Management Module

**Key Features:**
- Create new projects
- Create new tasks within projects
- View existing projects and tasks
- Optional: Archive or delete projects/tasks (with warnings about existing data)

**Implementation Logic:**
- **Get Unique Projects:** 
  ```r
  unique_projects <- time_log[, unique(project)]
  ```
- **Get Tasks by Project:**
  ```r
  tasks_for_project <- time_log[project == selected_project, unique(task)]
  ```
- **Add Project/Task:** Simple text input, validation against existing
- **Dynamic Lists:** Populate dropdowns using data.table's fast unique operations
- **Validation:** 
  ```r
  project_exists <- selected_project %in% time_log[, unique(project)]
  ```

#### 3.4 Data Display & Reporting Module

**Key Features:**
- View recent time entries (interactive table)
- Filter by project, task, date range
- Summary statistics:
  - Total hours by project
  - Total hours by task
  - Daily/weekly/monthly summaries
  - Current week/month progress
- Edit or delete existing entries (with confirmation)

**Implementation Logic using data.table:**

- **Filter by date range:**
  ```r
  filtered_log <- time_log[start_datetime >= input$date_from & 
                           start_datetime <= input$date_to]
  ```

- **Total hours by project:**
  ```r
  project_summary <- time_log[!is.na(end_datetime), 
                              .(total_hours = sum(hours, na.rm = TRUE)), 
                              by = project][order(-total_hours)]
  ```

- **Total hours by task:**
  ```r
  task_summary <- time_log[!is.na(end_datetime), 
                           .(total_hours = sum(hours, na.rm = TRUE)), 
                           by = .(project, task)][order(project, -total_hours)]
  ```

- **Daily summaries:**
  ```r
  time_log[, date := as.Date(start_datetime)]
  daily_summary <- time_log[!is.na(end_datetime), 
                            .(total_hours = sum(hours, na.rm = TRUE)), 
                            by = date][order(date)]
  ```

- **Current week summary:**
  ```r
  library(lubridate)
  current_week <- time_log[week(start_datetime) == week(Sys.Date()) & 
                           year(start_datetime) == year(Sys.Date()) &
                           !is.na(end_datetime), 
                           .(total_hours = sum(hours, na.rm = TRUE))]
  ```

- **Edit entry (update by reference):**
  ```r
  time_log[log_id == selected_id, 
           `:=`(project = new_project,
                task = new_task,
                start_datetime = new_start,
                end_datetime = new_end,
                hours = as.numeric(difftime(new_end, new_start, units = "hours")))]
  ```

- **Delete entry:**
  ```r
  time_log <- time_log[log_id != selected_id]
  ```

### 4. User Interface Layout

#### 4.1 Recommended Tab Structure

**Tab 1: Active Timer**
- Current timer status (if running)
- Project and task selectors
- Start/Stop buttons
- Elapsed time display (updates every second if timer running)

**Tab 2: Manual Entry**
- Form for manual time entry
- Submit button

**Tab 3: Time Log**
- Searchable/filterable data table
- Edit/delete functionality
- Export options (CSV download)

**Tab 4: Summary & Reports**
- Date range selector
- Summary tables and visualizations
- Total hours by project/task

**Tab 5: Settings/Management**
- Add new projects
- Add new tasks
- Manage existing projects/tasks
- Data import/export options

#### 4.2 UI Components Priority
- Clean, minimal design
- Clear visual distinction between active timer (green accent) and stopped state
- Confirmation dialogs for destructive actions (delete, stop timer with long duration)
- Responsive feedback (success messages, error alerts)

### 5. Data Persistence Strategy

#### 5.1 Storage Approach
**Recommended:** RDS file for data.table (preserves structure better) or CSV

**File Structure:**
```
app_data/
  ├── time_log.rds (or .csv)
  ├── projects.rds (optional)
  └── tasks.rds (optional)
```

#### 5.2 Read/Write Operations with data.table

- **On App Start:** 
  ```r
  if (file.exists("app_data/time_log.rds")) {
    time_log <- readRDS("app_data/time_log.rds")
    setDT(time_log)  # Ensure it's a data.table
    setkey(time_log, log_id)  # Set key for fast lookups
  } else {
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
    setkey(time_log, log_id)
  }
  ```

- **On Timer Start/Stop/Manual Entry:** 
  ```r
  saveRDS(time_log, "app_data/time_log.rds")
  # Or for CSV (note: may need special handling for POSIXct):
  fwrite(time_log, "app_data/time_log.csv")
  ```

- **Reading CSV with data.table:**
  ```r
  time_log <- fread("app_data/time_log.csv")
  # Convert datetime columns back to POSIXct
  time_log[, `:=`(start_datetime = as.POSIXct(start_datetime),
                  end_datetime = as.POSIXct(end_datetime))]
  ```

#### 5.3 Concurrent Access Considerations
- Use file locking if multiple users might access
- Implement error handling for failed reads/writes
- data.table's modify-by-reference is very efficient for updates
- Consider SQLite for multi-user scenarios (future enhancement)

### 6. Key Technical Considerations

#### 6.1 Reactive Architecture
- `reactiveValues()` for storing active timer state and time_log data.table
- `observe()` for auto-save operations
- `invalidateLater()` for updating elapsed time display (every 1000ms)
- Reactive expressions for filtered data

#### 6.2 data.table Best Practices
- Use `:=` for updating columns by reference (avoids copying)
- Set keys on frequently filtered columns for performance
- Use `fread()` and `fwrite()` for fast I/O
- Leverage data.table's concise syntax for grouping and aggregation
- Use `.SD` and `.SDcols` for complex operations on subsets
- Example of complex aggregation:
  ```r
  time_log[!is.na(end_datetime), 
           lapply(.SD, sum), 
           by = .(project, task), 
           .SDcols = "hours"]
  ```

#### 6.3 Time Zone Handling
- **Recommended:** Store all timestamps in UTC
- Display in user's local timezone
- Use `lubridate` package for time operations (works well with data.table)
- Document timezone assumptions clearly
- Example:
  ```r
  time_log[, start_datetime_local := with_tz(start_datetime, tzone = "America/New_York")]
  ```

#### 6.4 Validation & Error Handling
- Prevent starting timer if one is already active:
  ```r
  has_active_timer <- nrow(time_log[is.na(end_datetime)]) > 0
  ```
- Validate date/time inputs in manual entry
- Handle file I/O errors gracefully
- Validate that end_datetime > start_datetime
- Check for overlapping time entries (optional warning):
  ```r
  setorder(time_log, start_datetime)
  time_log[, overlaps := shift(end_datetime, type = "lag") > start_datetime, by = project]
  ```

#### 6.5 Data Integrity
- Assign unique `log_id` to each entry using auto-increment
- Implement confirmation before deletion
- Consider soft deletes (add `deleted` flag column) instead of hard deletes
- Regular data validation checks using data.table operations

### 7. Optional Enhancements (Future Roadmap)

#### 7.1 Basic Enhancements
- Notes/comments field for each time entry
- Project color coding
- Hourly rate tracking and billing calculations
  ```r
  time_log[, billing := hours * hourly_rate]
  ```
- Export to Excel with formatting
- Dark mode toggle

#### 7.2 Advanced Features
- Break timer (pause/resume functionality)
- Calendar view of time entries
- Goal setting (target hours per project)
- Email reports
- Mobile-responsive design
- Pomodoro timer integration
- Idle time detection warnings
- Rolling aggregations using data.table:
  ```r
  time_log[, rolling_7day := frollsum(hours, 7), by = project]
  ```

#### 7.3 Multi-User Features
- User authentication
- SQLite or database backend (data.table works great with databases via DBI)
- Shared projects with individual time tracking
- Administrative dashboard

### 8. Development Workflow Recommendations

1. **Phase 1:** Core timer functionality (start/stop, basic data storage with data.table)
2. **Phase 2:** Manual entry and project/task management
3. **Phase 3:** Data display and filtering using data.table operations
4. **Phase 4:** Summary reports and visualizations with data.table aggregations
5. **Phase 5:** Polish UI, add validations and error handling
6. **Phase 6:** Optional enhancements based on usage

### 9. data.table Performance Advantages

For this app, data.table offers:
- **Fast aggregations** for summary reports
- **Efficient filtering** for date ranges and project/task selection
- **Update by reference** (`:=`) avoids copying data, crucial for frequent timer updates
- **Fast I/O** with `fread()` and `fwrite()`
- **Memory efficiency** for growing time log data
- **Concise syntax** reduces code complexity

### 10. Testing Checklist

- [ ] Timer starts and records start_datetime correctly
- [ ] Timer stops and calculates hours accurately using data.table
- [ ] Active timer persists across app restarts
- [ ] Only one timer can be active at a time (checked with data.table subset)
- [ ] Manual entries validate date/time correctly
- [ ] Projects and tasks are created and retrieved using data.table unique()
- [ ] Data table displays and filters correctly
- [ ] Edit/delete operations work with data.table by-reference updates
- [ ] File I/O with fread/fwrite handles errors gracefully
- [ ] Time zone handling is consistent
- [ ] Aggregations and summaries calculate correctly
- [ ] UI is responsive and user-friendly

---

This revised design document emphasizes data.table usage throughout for efficient data manipulation and storage. Would you like me to elaborate on any specific data.table operations, or shall I proceed with creating the actual Shiny app code based on this specification?