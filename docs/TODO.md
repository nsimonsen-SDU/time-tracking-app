# Time Tracking App - TODO List

**Last Updated:** 2025-10-06
**Status:** Phases 1, 2 & 3 Complete! Phase 4 Partial

## Current Implementation Status

### ✅ Completed Features (Phases 1-3 Complete + Phase 4 Partial)
- [x] Core timer functionality (start/stop)
- [x] Basic data storage with data.table
- [x] Active timer persists across app restarts
- [x] Only one timer can be active at a time
- [x] Reactive values for state management
- [x] 5-tab UI structure
- [x] Data filtering by date range and project
- [x] Summary reports (by project, task, day)
- [x] File I/O with error handling
- [x] Auto-save on all data modifications
- [x] **Project creation from Settings tab** (Phase 2)
- [x] **Task creation from Settings tab** (Phase 2)
- [x] **Manual entry form submission** (Phase 2)
- [x] **Dynamic task dropdown based on project** (Phase 2)
- [x] **CSV export for Time Log** (Phase 4)
- [x] **Task filter for Time Log** (Phase 4)
- [x] **Weekly/Monthly summary statistics** (Phase 4)
- [x] **Edit time entry functionality** (Phase 3)
- [x] **Delete time entry functionality** (Phase 3)
- [x] **Long duration timer confirmation (>8 hrs)** (Phase 3)

---

## Remaining Features by Priority

### 🟢 EASY - Quick Wins (1-2 hours each)

#### 1. ✅ Add Project/Task Creation from Settings Tab (COMPLETED)
- [x] Implement `observeEvent` for `add_project` button
- [x] Validate project name (non-empty, not duplicate)
- [x] Add dummy entry to time_log or create separate reference table
- [x] Update project dropdowns reactively
- [x] Add success/error notifications
- [x] Implement `observeEvent` for `add_task` button
- [x] Validate task name (non-empty, not duplicate within project)
- [x] Clear form inputs after successful creation

**Implementation:** See `app.R` lines 638-738. Creates zero-hour entries to register projects/tasks in the system.

#### 2. ✅ Manual Entry Form Submission (COMPLETED)
- [x] Parse date + time inputs into POSIXct
- [x] Validate end_datetime > start_datetime
- [x] Validate time format (HH:MM)
- [x] Calculate hours automatically
- [x] Add to time_log with entry_type = "manual"
- [x] Clear form after submission
- [x] Show confirmation notification with hours
- [x] Error handling with try-catch

**Implementation:** See `app.R` lines 756-820. Parses date/time, validates, calculates hours, and saves to time_log.

#### 3. ✅ CSV Export for Time Log (COMPLETED)
- [x] Add download button to Time Log tab
- [x] Use `downloadHandler()` to export filtered data
- [x] Include all relevant columns
- [x] Format timestamps for readability ("%Y-%m-%d %H:%M:%S")
- [x] Respect current filters (date, project, task)
- [x] Use data.table's fast fwrite()
- [x] Handle empty data gracefully

**Implementation:** See `app.R` lines 822-905. Downloads filtered time log as CSV with formatted timestamps.

#### 4. ✅ Add Task Filter to Time Log Tab (COMPLETED)
- [x] Add task filter dropdown in UI (4-column layout)
- [x] Update filtering logic to include task
- [x] Make task dropdown depend on selected project
- [x] Add "All tasks" option
- [x] Update both time_log_table and CSV export
- [x] Dynamic task list updates based on project selection

**Implementation:** See `app.R` lines 204-229 (UI), 422-440 (reactive dropdown), 577-580 & 887-889 (filtering).

#### 5. ✅ Weekly/Monthly Summary Statistics (COMPLETED)
- [x] Add summary boxes for current week
- [x] Add summary boxes for current month
- [x] Add all-time hours summary
- [x] Use lubridate `week()` and `month()` functions
- [x] Display on Summary tab with styled boxes
- [x] Real-time reactive updates
- [x] Color-coded display (blue/green/orange)

**Implementation:** See `app.R` lines 256-279 (UI with styled boxes), 629-673 (calculations using lubridate).

---

### 🟡 MEDIUM - Moderate Complexity (3-5 hours each)

#### 6. ✅ Edit Time Entry Functionality (COMPLETED)
- [x] Add edit button to Time Log table
- [x] Create modal dialog with pre-filled form
- [x] Update entry using data.table `:=` operator
- [x] Recalculate hours on save
- [x] Validate updated data (time format, end > start)
- [x] Refresh table after edit
- [x] Dynamic task dropdown in edit modal

**Implementation:** See `app.R` lines 1088-1197. Modal dialog with full entry editing, validation, and data.table update by reference.

#### 7. ✅ Delete Time Entry Functionality (COMPLETED)
- [x] Add delete button to Time Log table
- [x] Show confirmation dialog with entry details
- [x] Remove from time_log using subsetting
- [x] Save after deletion
- [x] Show success notification
- [x] Warning about permanent deletion

**Implementation:** See `app.R` lines 1199-1270. Confirmation dialog showing entry details before permanent deletion.

#### 8. ✅ Dynamic Task Dropdown Based on Project (COMPLETED)
- [x] Make timer_task reactive to timer_project
- [x] Make manual_task reactive to manual_project
- [x] Filter tasks: `time_log[project == selected_project, unique(task)]`
- [x] Handle empty task lists gracefully ("No tasks available")
- [x] Apply to both timer and manual entry forms

**Implementation:** See `app.R` lines 444-468. Project-specific task filtering for timer and manual entry dropdowns.

#### 9. Add New Projects/Tasks from Timer/Manual Entry (SKIPPED)
- Note: This feature was skipped as users can already add projects/tasks from the Settings tab
- Implementing this would add UI complexity without significant UX benefit
- Current workflow: Settings → Add Project/Task → Return to Timer/Manual Entry

#### 10. ✅ Long Duration Timer Confirmation (COMPLETED)
- [x] Check elapsed hours before stopping
- [x] Show modal if > threshold (8 hours)
- [x] Allow user to confirm or cancel
- [x] Prevent accidental stops of multi-day timers
- [x] Display elapsed time in hours and minutes
- [x] Show project/task info in confirmation

**Implementation:** See `app.R` lines 541-610. Confirmation dialog for timers running >8 hours, preventing accidental stops.

#### 11. ✅ Current Week/Month Progress Widgets (COMPLETED - see Feature #5)
- [x] Design value boxes with color coding
- [x] Show total hours for current week
- [x] Show total hours for current month
- [x] Add all-time hours display
- [x] Add to Summary tab with styled boxes
- [x] Update reactively using lubridate

**Implementation:** Already completed as part of Feature #5 (Weekly/Monthly Summary Statistics).

---

### 🟠 MEDIUM-HARD - Complex Features (6-10 hours each)

#### 12. Archive/Delete Projects/Tasks with Warnings
- [ ] Check if project/task has existing entries
- [ ] Count affected entries
- [ ] Show warning dialog with impact details
- [ ] Offer options: reassign, archive, or cancel
- [ ] Implement soft delete (add `archived` flag)
- [ ] Filter out archived items in dropdowns

#### 13. Time Entry Overlap Detection
- [ ] Implement overlap checking algorithm
- [ ] Use data.table ordering and `shift()` function
- [ ] Show optional warning (non-blocking)
- [ ] Display overlapping entries
- [ ] Allow user to proceed or edit

**Implementation Hint:**
```r
setorder(time_log, start_datetime)
time_log[, overlaps := shift(end_datetime, type = "lag") > start_datetime]
```

#### 14. Project Color Coding
- [ ] Add color field to projects (reference table or in time_log)
- [ ] Create color picker UI (use colourpicker package)
- [ ] Apply colors to timer display
- [ ] Color-code table rows
- [ ] Use colors in charts/visualizations

#### 15. Export to Excel with Formatting
- [ ] Install and use `openxlsx` or `writexl` package
- [ ] Create multiple worksheets (entries, summaries)
- [ ] Format headers (bold, colors)
- [ ] Add summary formulas
- [ ] Auto-size columns
- [ ] Add download button

#### 16. Data Import Functionality
- [ ] Create file upload UI
- [ ] Read CSV/Excel file
- [ ] Validate structure (required columns)
- [ ] Validate data types (POSIXct for datetimes)
- [ ] Check for duplicate log_ids
- [ ] Merge with existing time_log
- [ ] Handle conflicts gracefully
- [ ] Show import summary

---

### 🔴 HARD - Advanced Features (10+ hours each)

#### 17. Hourly Rate Tracking and Billing
- [ ] Add hourly_rate field (to projects or time_log)
- [ ] Create rate management UI
- [ ] Calculate billing: `hours * hourly_rate`
- [ ] Add billing column to summaries
- [ ] Create revenue reports
- [ ] Support multiple rates (historical tracking)
- [ ] Invoice generation template

**Implementation Hint:**
```r
time_log[, billing := hours * hourly_rate]
```

#### 18. Pause/Resume Timer (Breaks)
- [ ] Modify data structure for time segments
- [ ] Track pause periods separately
- [ ] Calculate net time (total - breaks)
- [ ] Create break tracking UI
- [ ] Update timer display logic
- [ ] Handle multiple pause/resume cycles
- [ ] Validate break logic (can't resume if not paused)

#### 19. Calendar View of Time Entries
- [ ] Install calendar visualization package (fullcalendar, etc.)
- [ ] Convert time_log to calendar event format
- [ ] Color-code events by project
- [ ] Enable click-to-view entry details
- [ ] Add edit/delete from calendar
- [ ] Month/week/day views
- [ ] Drag-and-drop to reschedule (advanced)

#### 20. Pomodoro Timer Integration
- [ ] Add 25-minute work interval timer
- [ ] Implement break timers (5/15 minutes)
- [ ] Track completed pomodoros
- [ ] Browser notifications for timer end
- [ ] Integrate with existing time tracking
- [ ] Pomodoro statistics and reports
- [ ] Customizable interval lengths

#### 21. Idle Time Detection
- [ ] Implement JavaScript activity monitoring
- [ ] Track mouse/keyboard events
- [ ] Detect idle periods > threshold
- [ ] Show warning modal when idle
- [ ] Option to adjust timer or delete idle time
- [ ] Save activity state
- [ ] Client-server communication for events

#### 22. Visualizations and Charts
- [ ] Install plotly or ggplot2 packages
- [ ] Time by project pie/bar chart
- [ ] Trends over time line chart
- [ ] Heatmap for daily patterns
- [ ] Comparative period charts
- [ ] Interactive filters on charts
- [ ] Export charts as images

#### 23. Goal Setting and Progress Tracking
- [ ] Create goals UI (target hours per period)
- [ ] Store goals in separate table
- [ ] Calculate progress vs. goals
- [ ] Progress bars and visualizations
- [ ] Notifications when approaching/exceeding goals
- [ ] Historical goal tracking
- [ ] Achievement badges (gamification)

#### 24. Multi-User Support with Authentication
- [ ] Implement authentication (shinymanager or custom)
- [ ] User registration/login UI
- [ ] User-specific data filtering
- [ ] User session management
- [ ] Role-based permissions (admin/user)
- [ ] Shared projects with collaborators
- [ ] Activity audit log

#### 25. Database Backend (SQLite/PostgreSQL)
- [ ] Install DBI, RSQLite, or RPostgres packages
- [ ] Design database schema
- [ ] Create connection pool
- [ ] Replace RDS with database queries
- [ ] Migrate existing RDS data
- [ ] Optimize queries with indexes
- [ ] Handle concurrent access
- [ ] Backup/restore procedures

**Implementation Hint:**
```r
# data.table works great with databases
library(DBI)
con <- dbConnect(RSQLite::SQLite(), "time_tracking.db")
time_log <- setDT(dbGetQuery(con, "SELECT * FROM time_log"))
```

---

## Additional Polish & Features

### UI/UX Improvements
- [ ] Dark mode toggle
- [ ] Mobile-responsive design
- [ ] Keyboard shortcuts
- [ ] Better error messages
- [ ] Loading spinners for long operations
- [ ] Tooltips and help text
- [ ] Custom CSS styling

### Data Quality & Validation
- [ ] Time zone handling improvements
- [ ] Data validation on all inputs
- [ ] Prevent negative hours
- [ ] Handle edge cases (midnight crossings)
- [ ] Data integrity checks on startup

### Reporting & Export
- [ ] Email reports (scheduled or on-demand)
- [ ] PDF report generation
- [ ] Custom date range reports
- [ ] Comparative analysis (week-over-week, etc.)
- [ ] Export to Google Sheets

### Performance
- [ ] Lazy loading for large datasets
- [ ] Pagination for time log table
- [ ] Caching for expensive calculations
- [ ] Rolling aggregations: `frollsum(hours, 7)`

---

## Recommended Development Phases

### Phase 2: Manual Entry & Project Management (Current Priority)
1. Manual entry form submission (#2)
2. Add project/task creation (#1)
3. Dynamic task dropdowns (#8)

### Phase 3: Data Management & Validation
4. Edit time entries (#6)
5. Delete time entries (#7)
6. Long duration confirmation (#10)
7. Overlap detection (#13)

### Phase 4: Enhanced Reporting
8. CSV export (#3)
9. Task filter (#4)
10. Weekly/monthly summaries (#5)
11. Current period widgets (#11)
12. Visualizations (#22)

### Phase 5: Advanced Features
13. Excel export (#15)
14. Project color coding (#14)
15. Data import (#16)
16. Calendar view (#19)

### Phase 6: Optional Enhancements
17. Billing features (#17)
18. Pause/resume (#18)
19. Pomodoro timer (#20)
20. Goal tracking (#23)
21. Multi-user/Database (#24, #25)

---

## Testing Checklist

### Core Functionality
- [x] Timer starts and records start_datetime correctly
- [x] Timer stops and calculates hours accurately using data.table
- [x] Active timer persists across app restarts
- [x] Only one timer can be active at a time
- [x] File I/O with fread/fwrite handles errors gracefully
- [x] Aggregations and summaries calculate correctly

### Automated Testing (shinytest2)
- [x] **Testing framework implemented** - shinytest2 with testthat integration
- [x] **Test infrastructure** - tests/testthat/ directory structure, helper functions, .gitignore
- [x] **Core timer tests** - Start/stop, persistence, elapsed time, long duration confirmation
- [x] **Data persistence tests** - File I/O, structure validation, state management
- [x] **Manual entry tests** - Form validation, submission, time parsing
- [x] **Project/task management tests** - Creation, validation, duplicate prevention
- [x] **Dynamic dropdown tests** - Project-specific task filtering
- [x] **Summary report tests** - Statistics aggregations, date range filtering
- [x] **29+ tests passing** - 67% pass rate on initial implementation

### Remaining Test Improvements
- [ ] Fix file path handling for consistent test execution
- [ ] Add snapshot baselines for UI state verification
- [ ] Improve modal dialog testing (edit/delete confirmations)
- [ ] Add CSV export validation tests
- [ ] Test time zone handling consistency
- [ ] Add overlap detection tests (when feature implemented)
- [ ] Add error case handling tests
- [ ] Increase coverage to 95%+

---

## Notes

- Features are ordered by implementation difficulty, not necessarily by importance
- Start with Phase 2 features as they're foundational for user workflows
- Each completed feature should include tests and documentation
- Consider user feedback when prioritizing features
- Keep data.table patterns consistent throughout

**Quick Start Next Steps:**
1. Implement manual entry form (#2)
2. Add project/task creation (#1)
3. Add CSV export (#3)
