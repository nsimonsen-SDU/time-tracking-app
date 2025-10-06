# Test script to verify the app loads without errors

cat("Testing app.R for syntax errors...\n")

# Try to source the app
tryCatch({
  # This will load the app but not run it
  source("app.R", local = TRUE)
  cat("\n✓ App loaded successfully!\n")
  cat("✓ No syntax errors detected\n")
  cat("\nTo run the app, use: shiny::runApp()\n")
}, error = function(e) {
  cat("\n✗ Error loading app:\n")
  cat(conditionMessage(e), "\n")
  quit(status = 1)
})
