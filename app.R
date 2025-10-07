# Time Tracking Shiny App
# Main application file

# Load required libraries
library(shiny)
library(data.table)
library(lubridate)
library(DT)
library(shinyjs)
library(shinymanager)

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

#' Initialize an empty time log data.table with proper schema
#' @return data.table with correct column types and key
initialize_time_log <- function() {
  dt <- data.table(
    log_id = integer(),
    project = character(),
    task = character(),
    start_datetime = as.POSIXct(character()),
    end_datetime = as.POSIXct(character()),
    hours = numeric(),
    notes = character(),
    entry_type = character()
  )
  setkey(dt, log_id)
  return(dt)
}

#' Load time log from RDS file or initialize if doesn't exist
#' @return data.table with time log data
load_time_log <- function() {
  data_file <- "app_data/time_log.rds"

  # Create directory if it doesn't exist
  if (!dir.exists("app_data")) {
    dir.create("app_data", recursive = TRUE)
  }

  # Load existing data or initialize new
  if (file.exists(data_file)) {
    tryCatch({
      dt <- readRDS(data_file)
      setDT(dt)  # Ensure it's a data.table
      setkey(dt, log_id)  # Set key for fast lookups
      message("Loaded existing time log with ", nrow(dt), " entries")
      return(dt)
    }, error = function(e) {
      warning("Error loading time log file: ", e$message, ". Initializing new.")
      return(initialize_time_log())
    })
  } else {
    message("No existing time log found. Initializing new.")
    return(initialize_time_log())
  }
}

#' Save time log to RDS file
#' @param time_log data.table to save
#' @return logical indicating success
save_time_log <- function(time_log) {
  data_file <- "app_data/time_log.rds"

  # Create directory if it doesn't exist
  if (!dir.exists("app_data")) {
    dir.create("app_data", recursive = TRUE)
  }

  tryCatch({
    saveRDS(time_log, data_file)
    message("Time log saved successfully (", nrow(time_log), " entries)")
    return(TRUE)
  }, error = function(e) {
    warning("Error saving time log: ", e$message)
    return(FALSE)
  })
}

# ==============================================================================
# USER INTERFACE
# ==============================================================================

ui <- fluidPage(
  useShinyjs(),

  # Add logout button in the header
  tags$div(
    style = "position: absolute; top: 10px; right: 15px; z-index: 1000;",
    actionButton("logout", "Logout", icon = icon("sign-out-alt"), class = "btn-sm")
  ),

  titlePanel("Time Tracking App"),

  tabsetPanel(
    # -------------------------------------------------------------------------
    # TAB 1: Active Timer
    # -------------------------------------------------------------------------
    tabPanel(
      "Active Timer",
      br(),
      h3("Current Timer Status"),
      uiOutput("timer_status_display"),
      hr(),

      fluidRow(
        column(6,
          selectInput("timer_project",
                     "Project:",
                     choices = NULL,
                     width = "100%")
        ),
        column(6,
          selectInput("timer_task",
                     "Task:",
                     choices = NULL,
                     width = "100%")
        )
      ),

      fluidRow(
        column(6,
          actionButton("start_timer",
                      "Start Timer",
                      icon = icon("play"),
                      class = "btn-success btn-lg",
                      width = "100%")
        ),
        column(6,
          actionButton("stop_timer",
                      "Stop Timer",
                      icon = icon("stop"),
                      class = "btn-danger btn-lg",
                      width = "100%")
        )
      ),

      br(),
      h4("Elapsed Time:"),
      verbatimTextOutput("elapsed_time_display")
    ),

    # -------------------------------------------------------------------------
    # TAB 2: Manual Entry
    # -------------------------------------------------------------------------
    tabPanel(
      "Manual Entry",
      br(),
      h3("Add Time Entry Manually"),

      fluidRow(
        column(6,
          selectInput("manual_project",
                     "Project:",
                     choices = NULL,
                     width = "100%")
        ),
        column(6,
          selectInput("manual_task",
                     "Task:",
                     choices = NULL,
                     width = "100%")
        )
      ),

      fluidRow(
        column(6,
          dateInput("manual_start_date",
                   "Start Date:",
                   value = Sys.Date(),
                   width = "100%"),
          textInput("manual_start_time",
                   "Start Time (HH:MM):",
                   value = "09:00",
                   width = "100%")
        ),
        column(6,
          dateInput("manual_end_date",
                   "End Date:",
                   value = Sys.Date(),
                   width = "100%"),
          textInput("manual_end_time",
                   "End Time (HH:MM):",
                   value = "10:00",
                   width = "100%")
        )
      ),

      textAreaInput("manual_notes",
                   "Notes (optional):",
                   value = "",
                   rows = 3,
                   width = "100%"),

      actionButton("submit_manual",
                  "Submit Entry",
                  icon = icon("check"),
                  class = "btn-primary btn-lg",
                  width = "100%")
    ),

    # -------------------------------------------------------------------------
    # TAB 3: Time Log
    # -------------------------------------------------------------------------
    tabPanel(
      "Time Log",
      br(),
      h3("View and Edit Time Entries"),

      fluidRow(
        column(3,
          dateInput("filter_start_date",
                   "From:",
                   value = Sys.Date() - 7,
                   width = "100%")
        ),
        column(3,
          dateInput("filter_end_date",
                   "To:",
                   value = Sys.Date(),
                   width = "100%")
        ),
        column(3,
          selectInput("filter_project",
                     "Filter by Project:",
                     choices = c("All" = "all"),
                     width = "100%")
        ),
        column(3,
          selectInput("filter_task",
                     "Filter by Task:",
                     choices = c("All" = "all"),
                     width = "100%")
        )
      ),

      br(),
      DTOutput("time_log_table"),
      br(),

      fluidRow(
        column(3,
          downloadButton("download_csv",
                        "Download as CSV",
                        icon = icon("download"),
                        class = "btn-success")
        ),
        column(3,
          actionButton("edit_entry",
                      "Edit Selected",
                      icon = icon("edit"),
                      class = "btn-primary")
        ),
        column(3,
          actionButton("delete_entry",
                      "Delete Selected",
                      icon = icon("trash"),
                      class = "btn-danger")
        ),
        column(3,
          p(textOutput("selected_entry_info"), style = "margin-top: 8px; font-size: 12px;")
        )
      )
    ),

    # -------------------------------------------------------------------------
    # TAB 4: Summary & Reports
    # -------------------------------------------------------------------------
    tabPanel(
      "Summary & Reports",
      br(),
      h3("Time Summary Statistics"),

      # Current Period Summaries
      fluidRow(
        column(4,
          div(class = "well",
            h4(icon("calendar-week"), " This Week"),
            h2(textOutput("current_week_hours"), style = "color: #3c8dbc;"),
            p("Total hours tracked this week")
          )
        ),
        column(4,
          div(class = "well",
            h4(icon("calendar"), " This Month"),
            h2(textOutput("current_month_hours"), style = "color: #00a65a;"),
            p("Total hours tracked this month")
          )
        ),
        column(4,
          div(class = "well",
            h4(icon("chart-line"), " All Time"),
            h2(textOutput("all_time_hours"), style = "color: #f39c12;"),
            p("Total hours tracked")
          )
        )
      ),

      br(),
      hr(),
      h3("Custom Date Range Reports"),

      fluidRow(
        column(6,
          dateInput("summary_start_date",
                   "From:",
                   value = Sys.Date() - 30,
                   width = "100%")
        ),
        column(6,
          dateInput("summary_end_date",
                   "To:",
                   value = Sys.Date(),
                   width = "100%")
        )
      ),

      br(),
      h4("Total Hours by Project"),
      DTOutput("summary_by_project"),

      br(),
      h4("Total Hours by Task"),
      DTOutput("summary_by_task"),

      br(),
      h4("Daily Summary"),
      DTOutput("summary_by_day")
    ),

    # -------------------------------------------------------------------------
    # TAB 5: Settings
    # -------------------------------------------------------------------------
    tabPanel(
      "Settings",
      br(),
      h3("Project and Task Management"),

      fluidRow(
        column(6,
          h4("Add New Project"),
          textInput("new_project_name",
                   "Project Name:",
                   width = "100%"),
          actionButton("add_project",
                      "Add Project",
                      icon = icon("plus"),
                      class = "btn-primary",
                      width = "100%")
        ),
        column(6,
          h4("Add New Task"),
          selectInput("task_project_select",
                     "For Project:",
                     choices = NULL,
                     width = "100%"),
          textInput("new_task_name",
                   "Task Name:",
                   width = "100%"),
          actionButton("add_task",
                      "Add Task",
                      icon = icon("plus"),
                      class = "btn-primary",
                      width = "100%")
        )
      ),

      br(),
      hr(),
      h4("Existing Projects and Tasks"),
      verbatimTextOutput("existing_projects_tasks"),

      br(),
      hr(),

      # User Management Section (Admin Only)
      h3("User Management"),
      p(class = "text-muted", "Add and manage user accounts (Admin only)"),

      fluidRow(
        column(6,
          h4("Add New User"),
          textInput("new_username",
                   "Username:",
                   width = "100%"),
          passwordInput("new_user_password",
                       "Password:",
                       width = "100%"),
          checkboxInput("new_user_admin",
                       "Administrator privileges",
                       value = FALSE),
          actionButton("add_user",
                      "Add User",
                      icon = icon("user-plus"),
                      class = "btn-success",
                      width = "100%")
        ),
        column(6,
          h4("Change Password"),
          passwordInput("current_password",
                       "Current Password:",
                       width = "100%"),
          passwordInput("new_password",
                       "New Password:",
                       width = "100%"),
          passwordInput("confirm_password",
                       "Confirm New Password:",
                       width = "100%"),
          actionButton("change_password",
                      "Change Password",
                      icon = icon("key"),
                      class = "btn-warning",
                      width = "100%")
        )
      ),

      br(),
      hr(),
      h4("Existing Users"),
      p(class = "text-muted", "List of all registered users"),
      DTOutput("users_table"),

      br(),
      hr(),
      h4("Data Management"),
      p("Export and import functionality coming soon...")
    )
  )
)

# Wrap UI with authentication
ui <- secure_app(ui,
                 theme = "flatly",
                 language = "en",
                 choose_language = FALSE,
                 enable_admin = TRUE)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================

server <- function(input, output, session) {

  # ----------------------------------------------------------------------------
  # Authentication
  # ----------------------------------------------------------------------------

  # Secure server with credentials check
  res_auth <- secure_server(
    check_credentials = check_credentials(
      db = "app_data/credentials.sqlite",
      passphrase = "timetracking_secure_passphrase_2025"
    )
  )

  # Handle logout
  observeEvent(input$logout, {
    logout_user()
  })

  # ----------------------------------------------------------------------------
  # Reactive Values
  # ----------------------------------------------------------------------------

  rv <- reactiveValues(
    time_log = NULL,
    active_timer_id = NULL,
    current_user = NULL
  )

  # ----------------------------------------------------------------------------
  # Startup Logic
  # ----------------------------------------------------------------------------

  observe({
    # Load time log on startup
    rv$time_log <- load_time_log()

    # Check for active timer
    if (nrow(rv$time_log) > 0) {
      active_timers <- rv$time_log[is.na(end_datetime)]
      if (nrow(active_timers) > 0) {
        rv$active_timer_id <- active_timers$log_id[1]
        message("Found active timer with ID: ", rv$active_timer_id)
      }
    }

    # Save the loaded (possibly empty) time log
    save_time_log(rv$time_log)
  }) %>% bindEvent(session$clientData, once = TRUE)

  # ----------------------------------------------------------------------------
  # Reactive Expressions
  # ----------------------------------------------------------------------------

  # Get unique projects
  unique_projects <- reactive({
    req(rv$time_log)
    projects <- unique(rv$time_log$project)
    if (length(projects) == 0) {
      return(c("Sample Project"))
    }
    return(sort(projects))
  })

  # Get unique tasks for selected project
  unique_tasks <- reactive({
    req(rv$time_log)
    tasks <- unique(rv$time_log$task)
    if (length(tasks) == 0) {
      return(c("Sample Task"))
    }
    return(sort(tasks))
  })

  # Check if timer is active
  has_active_timer <- reactive({
    req(rv$time_log)
    return(!is.null(rv$active_timer_id) &&
           nrow(rv$time_log[is.na(end_datetime)]) > 0)
  })

  # ----------------------------------------------------------------------------
  # Update UI Elements
  # ----------------------------------------------------------------------------

  # Update project dropdowns
  observe({
    projects <- unique_projects()
    updateSelectInput(session, "timer_project", choices = projects)
    updateSelectInput(session, "manual_project", choices = projects)
    updateSelectInput(session, "task_project_select", choices = projects)
    updateSelectInput(session, "filter_project",
                     choices = c("All" = "all", projects))
  })

  # Update timer task dropdown based on selected project
  observe({
    req(rv$time_log, input$timer_project)

    tasks <- rv$time_log[project == input$timer_project, unique(task)]

    if (length(tasks) == 0) {
      tasks <- c("No tasks available")
    }

    updateSelectInput(session, "timer_task", choices = sort(tasks))
  })

  # Update manual entry task dropdown based on selected project
  observe({
    req(rv$time_log, input$manual_project)

    tasks <- rv$time_log[project == input$manual_project, unique(task)]

    if (length(tasks) == 0) {
      tasks <- c("No tasks available")
    }

    updateSelectInput(session, "manual_task", choices = sort(tasks))
  })

  # Update filter_task dropdown based on selected project
  observe({
    req(rv$time_log)
    req(input$filter_project)

    if (input$filter_project == "all") {
      # Show all tasks if "All" projects selected
      tasks <- unique(rv$time_log$task)
    } else {
      # Show tasks for selected project only
      tasks <- rv$time_log[project == input$filter_project, unique(task)]
    }

    if (length(tasks) == 0) {
      tasks <- character(0)
    }

    updateSelectInput(session, "filter_task",
                     choices = c("All" = "all", sort(tasks)))
  })

  # Enable/disable timer buttons
  observe({
    if (has_active_timer()) {
      shinyjs::disable("start_timer")
      shinyjs::enable("stop_timer")
    } else {
      shinyjs::enable("start_timer")
      shinyjs::disable("stop_timer")
    }
  })

  # ----------------------------------------------------------------------------
  # Timer Start/Stop Logic
  # ----------------------------------------------------------------------------

  # Start timer
  observeEvent(input$start_timer, {
    req(input$timer_project, input$timer_task)

    # Check no active timer exists
    if (has_active_timer()) {
      showNotification("A timer is already running!", type = "error")
      return()
    }

    # Create new timer entry
    new_id <- max(rv$time_log$log_id, 0) + 1
    new_entry <- data.table(
      log_id = new_id,
      project = input$timer_project,
      task = input$timer_task,
      start_datetime = Sys.time(),
      end_datetime = as.POSIXct(NA),
      hours = NA_real_,
      notes = "",
      entry_type = "timer"
    )

    # Add to time log
    rv$time_log <- rbindlist(list(rv$time_log, new_entry), use.names = TRUE)
    setkey(rv$time_log, log_id)

    # Set active timer
    rv$active_timer_id <- new_id

    # Save
    save_time_log(rv$time_log)

    showNotification("Timer started!", type = "message")
  })

  # Stop timer
  observeEvent(input$stop_timer, {
    req(rv$active_timer_id)

    # Get active timer entry
    active_entry <- rv$time_log[log_id == rv$active_timer_id]
    elapsed_hours <- as.numeric(difftime(Sys.time(), active_entry$start_datetime, units = "hours"))

    # Check if timer has been running for more than 8 hours
    if (elapsed_hours > 8) {
      showModal(modalDialog(
        title = "Confirm Stop Timer",
        tags$p(
          "This timer has been running for ",
          tags$strong(sprintf("%.1f hours", elapsed_hours)),
          " (",
          tags$strong(sprintf("%d hours and %d minutes", floor(elapsed_hours), floor((elapsed_hours - floor(elapsed_hours)) * 60))),
          ")."
        ),
        tags$p("Are you sure you want to stop it?"),
        tags$hr(),
        tags$p(
          tags$strong("Project:"), active_entry$project, tags$br(),
          tags$strong("Task:"), active_entry$task, tags$br(),
          tags$strong("Started:"), format(active_entry$start_datetime, "%Y-%m-%d %H:%M:%S")
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton("confirm_stop_timer", "Yes, Stop Timer", class = "btn-danger")
        ),
        easyClose = FALSE
      ))
    } else {
      # Normal stop without confirmation
      stop_time <- Sys.time()
      rv$time_log[log_id == rv$active_timer_id,
                  `:=`(end_datetime = stop_time,
                       hours = as.numeric(difftime(stop_time, start_datetime, units = "hours")))]

      # Clear active timer
      rv$active_timer_id <- NULL

      # Save
      save_time_log(rv$time_log)

      showNotification("Timer stopped!", type = "message")
    }
  })

  # Confirm stop timer (for long duration timers)
  observeEvent(input$confirm_stop_timer, {
    req(rv$active_timer_id)

    # Update the timer entry
    stop_time <- Sys.time()
    rv$time_log[log_id == rv$active_timer_id,
                `:=`(end_datetime = stop_time,
                     hours = as.numeric(difftime(stop_time, start_datetime, units = "hours")))]

    # Clear active timer
    rv$active_timer_id <- NULL

    # Save
    save_time_log(rv$time_log)

    # Close modal
    removeModal()

    showNotification("Timer stopped!", type = "message")
  })

  # ----------------------------------------------------------------------------
  # Output: Timer Status Display
  # ----------------------------------------------------------------------------

  output$timer_status_display <- renderUI({
    if (has_active_timer()) {
      active_entry <- rv$time_log[log_id == rv$active_timer_id]
      tags$div(
        class = "alert alert-success",
        tags$h4(icon("clock"), " Timer Running"),
        tags$p(tags$strong("Project:"), active_entry$project),
        tags$p(tags$strong("Task:"), active_entry$task),
        tags$p(tags$strong("Started:"), format(active_entry$start_datetime, "%Y-%m-%d %H:%M:%S"))
      )
    } else {
      tags$div(
        class = "alert alert-secondary",
        tags$h4(icon("pause-circle"), " No Active Timer"),
        tags$p("Select a project and task, then click 'Start Timer' to begin tracking.")
      )
    }
  })

  # Update elapsed time display every second
  output$elapsed_time_display <- renderText({
    # Trigger update every second
    invalidateLater(1000, session)

    if (has_active_timer()) {
      active_entry <- rv$time_log[log_id == rv$active_timer_id]
      elapsed <- as.numeric(difftime(Sys.time(), active_entry$start_datetime, units = "hours"))

      hours <- floor(elapsed)
      minutes <- floor((elapsed - hours) * 60)
      seconds <- floor(((elapsed - hours) * 60 - minutes) * 60)

      sprintf("%02d:%02d:%02d (%.2f hours)", hours, minutes, seconds, elapsed)
    } else {
      "No timer running"
    }
  })

  # ----------------------------------------------------------------------------
  # Output: Time Log Table
  # ----------------------------------------------------------------------------

  output$time_log_table <- renderDT({
    req(rv$time_log)

    # Filter by date range and project
    filtered <- rv$time_log[!is.na(end_datetime)]

    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Message = "No completed time entries yet")))
    }

    # Apply date filter
    filtered <- filtered[as.Date(start_datetime) >= input$filter_start_date &
                        as.Date(start_datetime) <= input$filter_end_date]

    # Apply project filter
    if (input$filter_project != "all") {
      filtered <- filtered[project == input$filter_project]
    }

    # Apply task filter
    if (!is.null(input$filter_task) && input$filter_task != "all") {
      filtered <- filtered[task == input$filter_task]
    }

    # Format for display
    display_dt <- filtered[, .(
      ID = log_id,
      Project = project,
      Task = task,
      Start = format(start_datetime, "%Y-%m-%d %H:%M"),
      End = format(end_datetime, "%Y-%m-%d %H:%M"),
      Hours = round(hours, 2),
      Notes = notes,
      Type = entry_type
    )]

    datatable(
      display_dt,
      selection = 'single',
      options = list(
        pageLength = 10,
        order = list(list(0, 'desc'))
      ),
      rownames = FALSE
    )
  })

  # ----------------------------------------------------------------------------
  # Output: Summary Tables
  # ----------------------------------------------------------------------------

  # Current week hours
  output$current_week_hours <- renderText({
    req(rv$time_log)

    current_week_data <- rv$time_log[week(start_datetime) == week(Sys.Date()) &
                                     year(start_datetime) == year(Sys.Date()) &
                                     !is.na(end_datetime),
                                     .(total_hours = sum(hours, na.rm = TRUE))]

    if (nrow(current_week_data) == 0 || current_week_data$total_hours == 0) {
      return("0.0 hrs")
    }

    paste0(round(current_week_data$total_hours, 1), " hrs")
  })

  # Current month hours
  output$current_month_hours <- renderText({
    req(rv$time_log)

    current_month_data <- rv$time_log[month(start_datetime) == month(Sys.Date()) &
                                      year(start_datetime) == year(Sys.Date()) &
                                      !is.na(end_datetime),
                                      .(total_hours = sum(hours, na.rm = TRUE))]

    if (nrow(current_month_data) == 0 || current_month_data$total_hours == 0) {
      return("0.0 hrs")
    }

    paste0(round(current_month_data$total_hours, 1), " hrs")
  })

  # All time hours
  output$all_time_hours <- renderText({
    req(rv$time_log)

    all_time_data <- rv$time_log[!is.na(end_datetime),
                                 .(total_hours = sum(hours, na.rm = TRUE))]

    if (nrow(all_time_data) == 0 || all_time_data$total_hours == 0) {
      return("0.0 hrs")
    }

    paste0(round(all_time_data$total_hours, 1), " hrs")
  })

  output$summary_by_project <- renderDT({
    req(rv$time_log)

    filtered <- rv$time_log[!is.na(end_datetime) &
                           as.Date(start_datetime) >= input$summary_start_date &
                           as.Date(start_datetime) <= input$summary_end_date]

    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Message = "No data in selected range")))
    }

    summary <- filtered[, .(Total_Hours = sum(hours, na.rm = TRUE)), by = project][order(-Total_Hours)]
    summary[, Total_Hours := round(Total_Hours, 2)]

    datatable(summary, options = list(pageLength = 10))
  })

  output$summary_by_task <- renderDT({
    req(rv$time_log)

    filtered <- rv$time_log[!is.na(end_datetime) &
                           as.Date(start_datetime) >= input$summary_start_date &
                           as.Date(start_datetime) <= input$summary_end_date]

    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Message = "No data in selected range")))
    }

    summary <- filtered[, .(Total_Hours = sum(hours, na.rm = TRUE)),
                       by = .(Project = project, Task = task)][order(Project, -Total_Hours)]
    summary[, Total_Hours := round(Total_Hours, 2)]

    datatable(summary, options = list(pageLength = 10))
  })

  output$summary_by_day <- renderDT({
    req(rv$time_log)

    filtered <- rv$time_log[!is.na(end_datetime) &
                           as.Date(start_datetime) >= input$summary_start_date &
                           as.Date(start_datetime) <= input$summary_end_date]

    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Message = "No data in selected range")))
    }

    filtered[, Date := as.Date(start_datetime)]
    summary <- filtered[, .(Total_Hours = sum(hours, na.rm = TRUE)), by = Date][order(Date)]
    summary[, Total_Hours := round(Total_Hours, 2)]

    datatable(summary, options = list(pageLength = 10))
  })

  # ----------------------------------------------------------------------------
  # Output: Existing Projects and Tasks
  # ----------------------------------------------------------------------------

  output$existing_projects_tasks <- renderPrint({
    req(rv$time_log)

    if (nrow(rv$time_log) == 0) {
      cat("No projects or tasks yet. Add your first time entry to get started!")
    } else {
      projects <- unique(rv$time_log$project)
      cat("Projects:\n")
      for (proj in sort(projects)) {
        cat("  -", proj, "\n")
        tasks <- unique(rv$time_log[project == proj]$task)
        for (task in sort(tasks)) {
          cat("      *", task, "\n")
        }
      }
    }
  })

  # ----------------------------------------------------------------------------
  # Project/Task Management
  # ----------------------------------------------------------------------------

  # Add new project
  observeEvent(input$add_project, {
    req(input$new_project_name)

    # Trim whitespace
    project_name <- trimws(input$new_project_name)

    # Validate: non-empty
    if (nchar(project_name) == 0) {
      showNotification("Project name cannot be empty!", type = "error")
      return()
    }

    # Validate: not duplicate
    existing_projects <- unique(rv$time_log$project)
    if (project_name %in% existing_projects) {
      showNotification("Project already exists!", type = "warning")
      return()
    }

    # Create a dummy entry to add the project to the system
    # This ensures the project appears in dropdowns
    new_id <- max(rv$time_log$log_id, 0) + 1
    dummy_entry <- data.table(
      log_id = new_id,
      project = project_name,
      task = "Initial Task",
      start_datetime = Sys.time(),
      end_datetime = Sys.time(),
      hours = 0,
      notes = "Auto-generated project entry",
      entry_type = "manual"
    )

    # Add to time_log
    rv$time_log <- rbindlist(list(rv$time_log, dummy_entry), use.names = TRUE)
    setkey(rv$time_log, log_id)

    # Save
    save_time_log(rv$time_log)

    # Clear input and show success
    updateTextInput(session, "new_project_name", value = "")
    showNotification(paste("Project '", project_name, "' created successfully!", sep = ""),
                     type = "message")
  })

  # Add new task
  observeEvent(input$add_task, {
    req(input$task_project_select, input$new_task_name)

    # Trim whitespace
    task_name <- trimws(input$new_task_name)
    project_name <- input$task_project_select

    # Validate: non-empty
    if (nchar(task_name) == 0) {
      showNotification("Task name cannot be empty!", type = "error")
      return()
    }

    # Validate: project exists
    existing_projects <- unique(rv$time_log$project)
    if (!(project_name %in% existing_projects)) {
      showNotification("Selected project does not exist!", type = "error")
      return()
    }

    # Validate: task doesn't already exist for this project
    existing_tasks <- rv$time_log[project == project_name, unique(task)]
    if (task_name %in% existing_tasks) {
      showNotification(paste("Task '", task_name, "' already exists for project '",
                            project_name, "'!", sep = ""), type = "warning")
      return()
    }

    # Create a dummy entry to add the task to the system
    new_id <- max(rv$time_log$log_id, 0) + 1
    dummy_entry <- data.table(
      log_id = new_id,
      project = project_name,
      task = task_name,
      start_datetime = Sys.time(),
      end_datetime = Sys.time(),
      hours = 0,
      notes = "Auto-generated task entry",
      entry_type = "manual"
    )

    # Add to time_log
    rv$time_log <- rbindlist(list(rv$time_log, dummy_entry), use.names = TRUE)
    setkey(rv$time_log, log_id)

    # Save
    save_time_log(rv$time_log)

    # Clear input and show success
    updateTextInput(session, "new_task_name", value = "")
    showNotification(paste("Task '", task_name, "' added to project '",
                          project_name, "'!", sep = ""), type = "message")
  })

  # Manual entry form submission
  observeEvent(input$submit_manual, {
    req(input$manual_project, input$manual_task,
        input$manual_start_date, input$manual_start_time,
        input$manual_end_date, input$manual_end_time)

    # Parse date + time inputs into POSIXct
    tryCatch({
      start_dt <- as.POSIXct(paste(input$manual_start_date, input$manual_start_time),
                            format = "%Y-%m-%d %H:%M")
      end_dt <- as.POSIXct(paste(input$manual_end_date, input$manual_end_time),
                          format = "%Y-%m-%d %H:%M")

      # Validate: check for NA (invalid time format)
      if (is.na(start_dt) || is.na(end_dt)) {
        showNotification("Invalid time format. Please use HH:MM format (e.g., 09:30).",
                        type = "error")
        return()
      }

      # Validate: end_datetime > start_datetime
      if (end_dt <= start_dt) {
        showNotification("End time must be after start time!", type = "error")
        return()
      }

      # Calculate hours automatically
      hours_calc <- as.numeric(difftime(end_dt, start_dt, units = "hours"))

      # Create new manual entry
      new_id <- max(rv$time_log$log_id, 0) + 1
      new_entry <- data.table(
        log_id = new_id,
        project = input$manual_project,
        task = input$manual_task,
        start_datetime = start_dt,
        end_datetime = end_dt,
        hours = hours_calc,
        notes = trimws(input$manual_notes),
        entry_type = "manual"
      )

      # Add to time_log
      rv$time_log <- rbindlist(list(rv$time_log, new_entry), use.names = TRUE)
      setkey(rv$time_log, log_id)

      # Save
      save_time_log(rv$time_log)

      # Clear form after submission
      updateTextInput(session, "manual_start_time", value = "09:00")
      updateTextInput(session, "manual_end_time", value = "10:00")
      updateTextAreaInput(session, "manual_notes", value = "")
      updateDateInput(session, "manual_start_date", value = Sys.Date())
      updateDateInput(session, "manual_end_date", value = Sys.Date())

      # Show confirmation notification
      showNotification(paste("Manual entry added successfully! (",
                            round(hours_calc, 2), " hours)", sep = ""),
                      type = "message")
    }, error = function(e) {
      showNotification(paste("Error creating manual entry:", e$message),
                      type = "error")
    })
  })

  # ----------------------------------------------------------------------------
  # CSV Export
  # ----------------------------------------------------------------------------

  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("time_log_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(rv$time_log)

      # Get filtered data (same logic as time_log_table)
      filtered <- rv$time_log[!is.na(end_datetime)]

      if (nrow(filtered) == 0) {
        # Create empty file with headers if no data
        empty_dt <- data.table(
          log_id = integer(),
          project = character(),
          task = character(),
          start_datetime = character(),
          end_datetime = character(),
          hours = numeric(),
          notes = character(),
          entry_type = character()
        )
        fwrite(empty_dt, file)
        return()
      }

      # Apply date filter
      filtered <- filtered[as.Date(start_datetime) >= input$filter_start_date &
                          as.Date(start_datetime) <= input$filter_end_date]

      # Apply project filter
      if (input$filter_project != "all") {
        filtered <- filtered[project == input$filter_project]
      }

      # Apply task filter
      if (!is.null(input$filter_task) && input$filter_task != "all") {
        filtered <- filtered[task == input$filter_task]
      }

      # Format timestamps for readability
      export_dt <- filtered[, .(
        log_id = log_id,
        project = project,
        task = task,
        start_datetime = format(start_datetime, "%Y-%m-%d %H:%M:%S"),
        end_datetime = format(end_datetime, "%Y-%m-%d %H:%M:%S"),
        hours = round(hours, 2),
        notes = notes,
        entry_type = entry_type
      )]

      # Write to CSV using data.table's fast fwrite
      fwrite(export_dt, file)
    }
  )

  # ----------------------------------------------------------------------------
  # Edit/Delete Time Entries
  # ----------------------------------------------------------------------------

  # Display selected entry info
  output$selected_entry_info <- renderText({
    if (length(input$time_log_table_rows_selected) > 0) {
      paste("Selected entry ID:", input$time_log_table_rows_selected)
    } else {
      "No entry selected"
    }
  })

  # Edit entry button
  observeEvent(input$edit_entry, {
    if (length(input$time_log_table_rows_selected) == 0) {
      showNotification("Please select an entry to edit", type = "warning")
      return()
    }

    # Get the filtered data to find the correct entry
    filtered <- rv$time_log[!is.na(end_datetime)]
    filtered <- filtered[as.Date(start_datetime) >= input$filter_start_date &
                        as.Date(start_datetime) <= input$filter_end_date]

    if (input$filter_project != "all") {
      filtered <- filtered[project == input$filter_project]
    }
    if (!is.null(input$filter_task) && input$filter_task != "all") {
      filtered <- filtered[task == input$filter_task]
    }

    # Get the selected row from filtered data
    selected_row <- input$time_log_table_rows_selected
    if (selected_row > nrow(filtered)) {
      showNotification("Invalid selection", type = "error")
      return()
    }

    entry <- filtered[selected_row]

    # Show edit modal
    showModal(modalDialog(
      title = paste("Edit Entry #", entry$log_id),
      selectInput("edit_project", "Project:",
                 choices = unique_projects(),
                 selected = entry$project),
      selectInput("edit_task", "Task:",
                 choices = rv$time_log[project == entry$project, unique(task)],
                 selected = entry$task),
      dateInput("edit_start_date", "Start Date:",
               value = as.Date(entry$start_datetime)),
      textInput("edit_start_time", "Start Time (HH:MM):",
               value = format(entry$start_datetime, "%H:%M")),
      dateInput("edit_end_date", "End Date:",
               value = as.Date(entry$end_datetime)),
      textInput("edit_end_time", "End Time (HH:MM):",
               value = format(entry$end_datetime, "%H:%M")),
      textAreaInput("edit_notes", "Notes:",
                   value = entry$notes, rows = 3),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("save_edit", "Save Changes", class = "btn-primary")
      ),
      easyClose = FALSE
    ))

    # Store the log_id for saving
    rv$editing_entry_id <- entry$log_id
  })

  # Update edit task dropdown when project changes
  observe({
    req(input$edit_project)
    tasks <- rv$time_log[project == input$edit_project, unique(task)]
    updateSelectInput(session, "edit_task", choices = sort(tasks))
  })

  # Save edited entry
  observeEvent(input$save_edit, {
    req(rv$editing_entry_id)

    tryCatch({
      # Parse datetimes
      start_dt <- as.POSIXct(paste(input$edit_start_date, input$edit_start_time),
                            format = "%Y-%m-%d %H:%M")
      end_dt <- as.POSIXct(paste(input$edit_end_date, input$edit_end_time),
                          format = "%Y-%m-%d %H:%M")

      # Validate
      if (is.na(start_dt) || is.na(end_dt)) {
        showNotification("Invalid time format", type = "error")
        return()
      }

      if (end_dt <= start_dt) {
        showNotification("End time must be after start time!", type = "error")
        return()
      }

      # Update entry
      rv$time_log[log_id == rv$editing_entry_id,
                 `:=`(project = input$edit_project,
                      task = input$edit_task,
                      start_datetime = start_dt,
                      end_datetime = end_dt,
                      hours = as.numeric(difftime(end_dt, start_dt, units = "hours")),
                      notes = trimws(input$edit_notes))]

      # Save
      save_time_log(rv$time_log)

      # Clear editing ID
      rv$editing_entry_id <- NULL

      # Close modal
      removeModal()

      showNotification("Entry updated successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error updating entry:", e$message), type = "error")
    })
  })

  # Delete entry button
  observeEvent(input$delete_entry, {
    if (length(input$time_log_table_rows_selected) == 0) {
      showNotification("Please select an entry to delete", type = "warning")
      return()
    }

    # Get the filtered data to find the correct entry
    filtered <- rv$time_log[!is.na(end_datetime)]
    filtered <- filtered[as.Date(start_datetime) >= input$filter_start_date &
                        as.Date(start_datetime) <= input$filter_end_date]

    if (input$filter_project != "all") {
      filtered <- filtered[project == input$filter_project]
    }
    if (!is.null(input$filter_task) && input$filter_task != "all") {
      filtered <- filtered[task == input$filter_task]
    }

    # Get the selected row
    selected_row <- input$time_log_table_rows_selected
    if (selected_row > nrow(filtered)) {
      showNotification("Invalid selection", type = "error")
      return()
    }

    entry <- filtered[selected_row]

    # Show confirmation dialog
    showModal(modalDialog(
      title = "Confirm Delete",
      tags$p("Are you sure you want to delete this entry?"),
      tags$hr(),
      tags$p(
        tags$strong("ID:"), entry$log_id, tags$br(),
        tags$strong("Project:"), entry$project, tags$br(),
        tags$strong("Task:"), entry$task, tags$br(),
        tags$strong("Hours:"), round(entry$hours, 2), tags$br(),
        tags$strong("Start:"), format(entry$start_datetime, "%Y-%m-%d %H:%M"), tags$br(),
        tags$strong("End:"), format(entry$end_datetime, "%Y-%m-%d %H:%M")
      ),
      tags$p(class = "text-danger", "This action cannot be undone!"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete", "Yes, Delete", class = "btn-danger")
      ),
      easyClose = FALSE
    ))

    # Store the log_id for deletion
    rv$deleting_entry_id <- entry$log_id
  })

  # Confirm delete
  observeEvent(input$confirm_delete, {
    req(rv$deleting_entry_id)

    # Remove entry
    rv$time_log <- rv$time_log[log_id != rv$deleting_entry_id]
    setkey(rv$time_log, log_id)

    # Save
    save_time_log(rv$time_log)

    # Clear deleting ID
    rv$deleting_entry_id <- NULL

    # Close modal
    removeModal()

    showNotification("Entry deleted successfully!", type = "message")
  })

  # ----------------------------------------------------------------------------
  # User Management
  # ----------------------------------------------------------------------------

  # Display users table
  output$users_table <- renderDT({
    # Read credentials from database
    tryCatch({
      con <- DBI::dbConnect(RSQLite::SQLite(), "app_data/credentials.sqlite")
      users <- DBI::dbReadTable(con, "credentials")
      DBI::dbDisconnect(con)

      # Display only necessary columns, hide password
      display_users <- users[, c("user", "admin", "start", "expire")]
      datatable(display_users,
                options = list(pageLength = 10, searching = TRUE),
                rownames = FALSE,
                selection = "single")
    }, error = function(e) {
      datatable(data.frame(Message = "Unable to load users"),
                options = list(dom = 't'),
                rownames = FALSE)
    })
  })

  # Add new user
  observeEvent(input$add_user, {
    req(input$new_username, input$new_user_password)

    # Validate inputs
    if (nchar(input$new_username) < 3) {
      showNotification("Username must be at least 3 characters", type = "error")
      return()
    }

    if (nchar(input$new_user_password) < 6) {
      showNotification("Password must be at least 6 characters", type = "error")
      return()
    }

    # Check if user is admin
    if (!isTRUE(res_auth$admin)) {
      showNotification("Only administrators can add users", type = "error")
      return()
    }

    tryCatch({
      # Create new credentials
      new_cred <- data.frame(
        user = input$new_username,
        password = input$new_user_password,
        admin = input$new_user_admin,
        stringsAsFactors = FALSE
      )

      # Add to database
      create_db(
        credentials_data = new_cred,
        sqlite_path = "app_data/credentials.sqlite",
        passphrase = "timetracking_secure_passphrase_2025"
      )

      showNotification(paste("User", input$new_username, "added successfully!"),
                      type = "message")

      # Clear inputs
      updateTextInput(session, "new_username", value = "")
      updateTextInput(session, "new_user_password", value = "")
      updateCheckboxInput(session, "new_user_admin", value = FALSE)

    }, error = function(e) {
      showNotification(paste("Error adding user:", e$message), type = "error")
    })
  })

  # Change password
  observeEvent(input$change_password, {
    req(input$current_password, input$new_password, input$confirm_password)

    # Validate inputs
    if (nchar(input$new_password) < 6) {
      showNotification("New password must be at least 6 characters", type = "error")
      return()
    }

    if (input$new_password != input$confirm_password) {
      showNotification("New passwords do not match", type = "error")
      return()
    }

    tryCatch({
      # Get current user
      current_user <- res_auth$user

      # Verify current password
      check_result <- check_credentials(
        db = "app_data/credentials.sqlite",
        passphrase = "timetracking_secure_passphrase_2025"
      )(data.frame(user = current_user, password = input$current_password))

      if (!check_result$result) {
        showNotification("Current password is incorrect", type = "error")
        return()
      }

      # Update password in database
      con <- DBI::dbConnect(RSQLite::SQLite(), "app_data/credentials.sqlite")

      # Hash new password using scrypt
      hashed_password <- scrypt::hashPassword(input$new_password)

      # Update password
      DBI::dbExecute(con,
                    "UPDATE credentials SET password = ? WHERE user = ?",
                    params = list(hashed_password, current_user))

      DBI::dbDisconnect(con)

      showNotification("Password changed successfully!", type = "message")

      # Clear inputs
      updateTextInput(session, "current_password", value = "")
      updateTextInput(session, "new_password", value = "")
      updateTextInput(session, "confirm_password", value = "")

    }, error = function(e) {
      showNotification(paste("Error changing password:", e$message), type = "error")
    })
  })
}

# ==============================================================================
# RUN APP
# ==============================================================================

shinyApp(ui = ui, server = server)
