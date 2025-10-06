# Install required packages for the Time Tracking App

packages <- c("shiny", "data.table", "lubridate", "DT", "shinyjs")

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, repos = "https://cran.rstudio.com")
  }
}

cat("All packages installed successfully!\n")
