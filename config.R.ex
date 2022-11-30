CONFIG <- list (
  api_key = "yourapikey",
  aws_secret = "your_aws_secret",
  aws_key = "your_aws_key",
  data_bucket = "micats-capacity"
)

credentials <- data.frame(
  user = c("user1",
           "user2",
           "admin")
  password = c("password1",
               "password2",
               "passwird3"),
  # password will automatically be hashed
  admin = c(FALSE,
            FALSE,
            TRUE),
  stringsAsFactors = FALSE
)
