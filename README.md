# MICATS

This is a simple shiny app to allow users to maintain a data table of pediatrics
beds that are available as we navigate the RSV surge of 2022.

## Pre-requisites

* An AWS account with key and secret associated with a root or IAM user with S3
access.
* An S3 bucket to store the data
* Edit config.R.ex to add your AWS credentials and desired initial logins for
the app, and save as config.R (you can edit the users later through the admin 
panel of the app).
* Install any missing R package dependencies:
```
deps <- c("shiny", 
          "shinythemes", 
          "shinybusy", 
          "shinymanager",
          "DT", 
          "DTedit", 
          "googleway", 
          "aws.s3")
ix <- which(deps %in% installed.packages())
if(length(ix) < length(deps)) {
  install.packages(deps[-ix])
}
```

## Installation

```
git clone https://github.com/ejkreboot/micats
cd micats
# edit config.R.ex and save as config.R and then...
shiny::runApp()
```

