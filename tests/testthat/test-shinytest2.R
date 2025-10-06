library(shinytest2)

test_that("Initial Shiny values are consistent", {
  app <- AppDriver$new()

  app$expect_values()
})


test_that("{shinytest2} recording: start-and-stop-timer", {
  app <- AppDriver$new(name = "start-and-stop-timer", height = 992, width = 1427)
  app$click("start_timer")
  app$click("stop_timer")
  app$expect_values()
})
