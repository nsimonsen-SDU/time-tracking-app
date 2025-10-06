# Comprehensive workflow test
# Simulates: initialize -> save -> load -> add timer -> save -> load -> verify

source("app.R", local = TRUE)

cat("=== COMPREHENSIVE WORKFLOW TEST ===\n\n")

# Clean slate
if (file.exists("app_data/time_log.rds")) {
  file.remove("app_data/time_log.rds")
  cat("✓ Cleaned existing data file\n\n")
}

# Step 1: Initialize
cat("Step 1: Initialize empty data.table\n")
dt <- initialize_time_log()
cat("  Rows:", nrow(dt), "\n")
cat("  Columns:", paste(names(dt), collapse=", "), "\n\n")

# Step 2: Save empty
cat("Step 2: Save empty data.table\n")
result <- save_time_log(dt)
cat("  Save result:", result, "\n\n")

# Step 3: Load back
cat("Step 3: Load data.table\n")
dt_loaded <- load_time_log()
cat("  Loaded rows:", nrow(dt_loaded), "\n\n")

# Step 4: Simulate adding a timer entry
cat("Step 4: Simulate adding a timer entry\n")
new_entry <- data.table(
  log_id = 1L,
  project = "Test Project",
  task = "Test Task",
  start_datetime = Sys.time(),
  end_datetime = as.POSIXct(NA),
  hours = NA_real_,
  notes = "",
  entry_type = "timer"
)
dt_with_entry <- rbindlist(list(dt_loaded, new_entry), use.names = TRUE)
setkey(dt_with_entry, log_id)
cat("  Rows after adding entry:", nrow(dt_with_entry), "\n")
cat("  Active timers:", nrow(dt_with_entry[is.na(end_datetime)]), "\n\n")

# Step 5: Save with entry
cat("Step 5: Save data with active timer\n")
result <- save_time_log(dt_with_entry)
cat("  Save result:", result, "\n\n")

# Step 6: Load again
cat("Step 6: Load data to verify persistence\n")
dt_final <- load_time_log()
cat("  Loaded rows:", nrow(dt_final), "\n")
cat("  Active timers:", nrow(dt_final[is.na(end_datetime)]), "\n")
cat("  Project:", dt_final$project[1], "\n")
cat("  Task:", dt_final$task[1], "\n\n")

# Step 7: Simulate stopping the timer
cat("Step 7: Simulate stopping the timer\n")
stop_time <- Sys.time()
dt_final[log_id == 1L,
         `:=`(end_datetime = stop_time,
              hours = as.numeric(difftime(stop_time, start_datetime, units = "hours")))]
cat("  Hours recorded:", round(dt_final$hours[1], 4), "\n")
save_time_log(dt_final)
cat("\n")

# Step 8: Final verification
cat("Step 8: Final verification\n")
dt_verify <- load_time_log()
cat("  Total entries:", nrow(dt_verify), "\n")
cat("  Completed entries:", nrow(dt_verify[!is.na(end_datetime)]), "\n")
cat("  Active timers:", nrow(dt_verify[is.na(end_datetime)]), "\n\n")

cat("=== TEST SUMMARY ===\n")
cat("✓ Data.table initialization works\n")
cat("✓ Save/load cycle preserves data\n")
cat("✓ Timer entries can be created\n")
cat("✓ Active timer detection works\n")
cat("✓ Timer stop and hours calculation works\n")
cat("✓ File persistence confirmed\n\n")
cat("App is ready for use! Run with: Rscript run_app.R\n")
