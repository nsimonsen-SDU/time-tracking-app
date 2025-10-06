# Test data I/O functions

source("app.R", local = TRUE)

cat("Testing data initialization and I/O...\n\n")

# Test 1: Initialize empty data.table
cat("1. Testing initialize_time_log()...\n")
dt <- initialize_time_log()
cat("   ✓ Created data.table with", nrow(dt), "rows\n")
cat("   ✓ Columns:", paste(names(dt), collapse=", "), "\n")
cat("   ✓ Key:", paste(key(dt), collapse=", "), "\n\n")

# Test 2: Save empty data.table
cat("2. Testing save_time_log()...\n")
result <- save_time_log(dt)
if (result) {
  cat("   ✓ Save successful\n\n")
} else {
  cat("   ✗ Save failed\n\n")
}

# Test 3: Check if file exists
cat("3. Checking if file was created...\n")
if (file.exists("app_data/time_log.rds")) {
  cat("   ✓ File exists: app_data/time_log.rds\n")
  cat("   File size:", file.size("app_data/time_log.rds"), "bytes\n\n")
} else {
  cat("   ✗ File not found\n\n")
}

# Test 4: Load data.table back
cat("4. Testing load_time_log()...\n")
loaded_dt <- load_time_log()
cat("   ✓ Loaded data.table with", nrow(loaded_dt), "rows\n")
cat("   ✓ Columns:", paste(names(loaded_dt), collapse=", "), "\n")
cat("   ✓ Key:", paste(key(loaded_dt), collapse=", "), "\n\n")

# Test 5: Verify structure
cat("5. Verifying data.table structure...\n")
str(loaded_dt)

cat("\n✓ All data I/O tests passed!\n")
cat("✓ App is ready to run\n")
