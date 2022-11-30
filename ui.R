#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinymanager)
library(DT)
library(DTedit)
library(shinythemes)
library(shinybusy)
library(googleway)
source("config.R")

set_labels(
  language = "en",
  "Please authenticate" = "Welcome to MI-CATS. Please Log In.",
  "Username:" = "User ID:",
  "Password:" = "Password:"
)

# Init the database
if (!file.exists("data/MICATS.sqlite")) {
  create_db(
    credentials_data = credentials, # from config.R
    sqlite_path = "data/MICATS.sqlite", # will be created
    passphrase = "MICATS"
  )
}

# Wrap your UI with secure_app, enabled admin mode or not
ui <- secure_app(
  theme = shinythemes::shinytheme("simplex"),
  tag_img = tags$img(
    src = "./logo.svg", width = 100
  ),
  fluidPage(
    busy_start_up(
      loader = spin_epic("orbit", color = "#FFF"),
      text = "Loading...",
      timeout = 1000,
      color = "#66f48c",
      background = "#012855"
    ),
    tags$head(
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "micatsstyle.css"
      )
    ),

    add_busy_spinner(spin = "fading-circle"),
    # Application title
    div(id = "title",
        div(class = "fleft", tags$image(src="logo.svg")),
        div(tags$h2("MI-CATS"))
    ),
    div(id = "welcome", "Welcome to the Michigan Children's Hospital Capacity Tracking System (MI-CATS). This tool was developed during the RSV surge of 2022 in an effort to streamline patient transfers."),
    shiny::verticalLayout(
      shiny::fluidRow(
        shiny::column(width=12,
                      div(id = "instructions",
                          "Click on a hospital's row in the table and then click the 'Edit' button to update"),
                      )),
        shiny::fluidRow(
          shiny::column(width = 4,
                        div(id = "map-container",
                            google_mapOutput(height = 600, width = 400, outputId = "map")
                        )),
          shiny::column(width = 8,
                        uiOutput('capacity'))
        )
    )
), enable_admin = TRUE)

