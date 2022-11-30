library(shiny)
library(DT)
library(googleway)
library(aws.s3)

# edit config.R.ex and save as config.R
source("config.R")

style <- paste(readLines("./data/map_style.json"), collapse = "\n")

server <- function(input, output, session) {
  cap <- reactivePoll(1000, session,
                      # This function returns the time that log_file was last modified
                      checkFunc = function() {
                        attr(aws.s3::head_object("captable.rds", "micats-capacity"), "last-modified")
                      },
                      # This function returns the content of log_file
                      valueFunc = function() {
                        dat <- s3readRDS("captable.rds",
                                         bucket = CONFIG$data_bucket,
                                         region = "us-east-2")
                        dat$Icon <- c("hospital_open_24.png", "hospital_closed_24.png")[factor(grepl("y|Y", dat$Open), levels=c(TRUE, FALSE))]
                        dat
                      }
  )

  cap.insert <- function(data, row) {
    updatedData <- rbind(data, as.data.frame(cap()))
    s3saveRDS(updatedData,
              "captable.rds",
              bucket = CONFIG$data_bucket,
              region = "us-east-2")
    updatedData
  }

  cap.update <- function(data, olddata, row) {
    updatedData <- as.data.frame(cap())
    updatedData[row,] <- data[row,]
    updatedData$Updated[row] <- date()
    updatedData$Icon <- c("hospital_open_24.png", "hospital_closed_24.png")[factor(grepl("y|Y", updatedData$Open), levels=c(TRUE, FALSE))]
    s3saveRDS(updatedData,
              "captable.rds",
              bucket = CONFIG$data_bucket,
              region = "us-east-2")
    google_map_update(map_id = "map") %>%
      add_markers(data = updatedData,
                  lat = "Latitude",
                  lon = "Longitude",
                  marker_icon = "Icon",
                  title = "Facility")
    updatedData
  }

  DTedit::dtedit(input, output,
                 datatable.options = list(
                  pageLength =  nrow(isolate(cap())),
                  paging = FALSE,
                  searching = FALSE
                 ),
                 name = 'capacity',
                 thedata = as.data.frame(isolate(cap())),
                 edit.cols = c('Open', 'Avail Beds', 'Notes'),
                 edit.label.cols = c('Open', 'Available Beds', 'Notes'),
                 input.choices = list("Open"=c("Y", "N")),
                 input.types = c("Open"='textInput', "Avail Beds"='numericInput', "Notes"="textAreaInput"),
                 view.cols = c('Facility', 'Open', 'Avail Beds', 'Updated'),
                 show.delete = FALSE,
                 show.insert = FALSE,
                 show.copy = FALSE,
                 callback.update = cap.update,
                 callback.insert = cap.delete)

  res_auth <- secure_server(
    session = session,
    keep_token = TRUE,
    check_credentials = check_credentials(
      "data/MICATS.sqlite",
      passphrase = "MICATS"
    )
  )

  output$cap <- renderTable({
    cap()
  })

  output$map <- renderGoogle_map({
    google_map(zoom = 10, width = 600, height=600, data = cap(), key = CONFIG$api_key, styles = style) %>%
      add_markers(lat = "Latitude",
                  lon = "Longitude",
                  marker_icon = "Icon",
                  title = "Facility")
  })
}

# style <- paste(readLines("data/map_style.json"), collapse = "\n")
# Hospital icons created by Freepik - Flaticon
