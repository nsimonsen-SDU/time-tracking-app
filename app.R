# Time Tracking Shiny App
# Main application file

# Load required libraries
library(shiny)
library(data.table)
library(lubridate)
library(DT)
library(shinyjs)

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
        column(4,
          dateInput("filter_start_date",
                   "From:",
                   value = Sys.Date() - 7,
                   width = "100%")
        ),
        column(4,
          dateInput("filter_end_date",
                   "To:",
                   value = Sys.Date(),
                   width = "100%")
        ),
        column(4,
          selectInput("filter_project",
                     "Filter by Project:",
                     choices = c("All" = "all"),
                     width = "100%")
        )
      ),

      br(),
      DTOutput("time_log_table"),
      br(),

      p("Edit and delete functionality coming soon...")
    ),

    # -------------------------------------------------------------------------
    # TAB 4: Summary & Reports
    # -------------------------------------------------------------------------
    tabPanel(
      "Summary & Reports",
      br(),
      h3("Time Summary Statistics"),

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
      h4("Data Management"),
      p("Export and import functionality coming soon...")
    )
  )
)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================

server <- function(input, output, session) {

  # ----------------------------------------------------------------------------
  # Reactive Values
  # ----------------------------------------------------------------------------

  rv <- reactiveValues(
    time_log = NULL,
    active_timer_id = NULL
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

  # Update task dropdowns
  observe({
    tasks <- unique_tasks()
    updateSelectInput(session, "timer_task", choices = tasks)
    updateSelectInput(session, "manual_task", choices = tasks)
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

    # Update the timer entry
    stop_time <- Sys.time()
    rv$time_log[log_id == rv$active_timer_id,
                `:=`(end_datetime = stop_time,
                     hours = as.numeric(difftime(stop_time, start_datetime, units = "hours")))]

    # Clear active timer
    rv$active_timer_id <- NULL

    # Save
    save_time_log(rv$time_log)

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

    # Format for display
    display_dt <- filtered[, .(
      ID = log_id,
      Project = project,
      Task = task,
      Start = format(start_datetime, "%Y-%m-%d %H:%M"),
      End = format(end_datetime, "%Y-%m-%d %H:%M"),
      Hours = round(hours, 2),
      Type = entry_type
    )]

    datatable(display_dt, options = list(pageLength = 10, order = list(list(0, 'desc'))))
  })

  # ----------------------------------------------------------------------------
  # Output: Summary Tables
  # ----------------------------------------------------------------------------

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

  observeEvent(input$submit_manual, {
    showNotification("Manual entry functionality coming soon!", type = "message")
  })
}

# ==============================================================================
# RUN APP
# ==============================================================================

shinyApp(ui = ui, server = server)
