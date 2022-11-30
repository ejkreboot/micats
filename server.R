library(shiny)
library(DT)
library(googleway)
library(aws.s3)

# edit config.R.ex and save as config.R
source("config.R")
captable <- if(CONFIG$dev) "captable_dev.rds" else "captable.rds"
style <- paste(readLines("./data/map_style.json"), collapse = "\n")

server <- function(input, output, session) {
  cap <- reactivePoll(1000, session,
                      # This function returns the time that log_file was last modified
                      checkFunc = function() {
                        #shinyjs::runjs("
                        #$('.odd').on('dblclick', function(){
                        #  console.log('hello');
                        #})")
                        attr(aws.s3::head_object(captable, "micats-capacity"), "last-modified")
                      },
                      # This function returns the content of log_file
                      valueFunc = function() {
                        dat <- s3readRDS(captable,
                                         bucket = CONFIG$data_bucket,
                                         region = "us-east-2")
                        dat$Icon <- c("hospital_open_24.png", "hospital_closed_24.png")[factor(grepl("y|Y", dat$Open), levels=c(TRUE, FALSE))]
                        ix <- which(grepl("c|C", dat$Open))
                        if(length(ix) > 0) {
                          dat$Icon[ix] <- "hospital_yellow_24.png"
                        }
                        dat
                      }
  )

  cap.insert <- function(data, row) {
    updatedData <- rbind(data, as.data.frame(cap()))
    s3saveRDS(updatedData,
              captable,
              bucket = CONFIG$data_bucket,
              region = "us-east-2")
    data.formatted(updatedData)
  }

  cap.update <- function(data, olddata, row) {
    updatedData <- as.data.frame(cap())
    updatedData[row,] <- data[row,]
    updatedData$Updated[row] <- date()
    updatedData$Icon <- c("hospital_open_24.png", "hospital_closed_24.png")[factor(grepl("y|Y", updatedData$Open), levels=c(TRUE, FALSE))]
    ix <- which(grepl("c|C", updatedData$Open))
    if(length(ix) > 0) {
      updatedData$Icon[ix] <- "hospital_yellow_24.png"
    }
    s3saveRDS(updatedData,
              captable,
              bucket = CONFIG$data_bucket,
              region = "us-east-2")
    google_map_update(map_id = "map") %>%
      add_markers(data = updatedData,
                  lat = "Latitude",
                  lon = "Longitude",
                  marker_icon = "Icon",
                  title = "Facility")
    data.formatted(updatedData)
  }

  data.formatted <- function(x = NULL) {
    if(is.null(x)) {
      dat <- isolate(cap())
    } else {
      dat <- x
    }
    dat$Updated <- format(as.POSIXlt(dat$Updated,
                                     format = "%a %b %d %H:%M:%S %Y"),
                          format = "%D")
    dat
  }

  DTedit::dtedit(input, output,
                 datatable.options = list(
                  pageLength =  nrow(isolate(cap())),
                  paging = FALSE,
                  searching = FALSE,
                  autoWidth = TRUE,
                  columnDefs = list(list(className = 'dt-center', targets = 1:3),
                                    list(width = "250px", targets=0))
                 ),
                 name = 'capacity',
                 thedata = as.data.frame(data.formatted()),
                 edit.cols = c('Open', 'Avail Beds', 'Latitude', 'Longitude', 'Notes'),
                 edit.label.cols = c('Open', 'Available Beds', 'Latitude', 'Longitude', 'Notes'),
                 input.choices = list("Open"=c("Y", "N", "C")),
                 input.types = c("Open"='selectInput', "Avail Beds"='numericInput', "Notes"="textAreaInput"),
                 view.cols = c('Facility', 'Open', 'Avail Beds', 'Updated', 'Notes'),
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

  output$cap <- renderTable(width = "600px", {
    cap()
  })

  output$map <- renderGoogle_map({
    data <- cap()
    data$Info <- paste("<b>", data$Facility, "</b><br>", data$Notes)
    google_map(search_box = TRUE,
               zoom_control = FALSE,
               map_type_control = FALSE,
               width = 400, height=650,
               data = data,
               key = CONFIG$api_key, styles = style) %>%
      add_markers(lat = "Latitude", mouse_over = "Info",
                  lon = "Longitude",
                  marker_icon = "Icon",
                  title = "Facility")
  })
}

# Hospital icons created by Freepik - Flaticon
