library(clock)
events_vct <- sub("\\.R", "", list.files("R", "^20"))
previous <- events_vct[as.Date(events_vct) < Sys.Date()]
n <- length(previous)
today <- date_today("Europe/Paris")
custom_start <- date_shift(
  x = date_build(2022, 3, 1),
  target = weekday(code = 1, encoding = "iso")
)
events <- date_shift(
  x = date_seq(
    from = max(c(as.Date(setdiff(events_vct, previous)), custom_start, today)),
    by = duration_weeks(2),
    total_size = 4
  ),
  target = weekday(code = 5, encoding = "iso")
)

rcode <- sprintf(
  paste(
    "create_game_night(",
    '  output = "posters/%s.png",',
    "  rmd_params = list(",
    '    number = "%s",',
    '    date = "%s %s %s 2022 à 19 h 30"',
    "  )",
    ")",
    sep = "\n"
  ),
  events,
  seq(n + 1, n + length(events), 1),
  (function(x) {
    s <- as.character(x)
    paste0(
      toupper(substring(s, 1, 1)),
      substring(s, 2)
    )
  })(date_weekday_factor(events, labels = "fr", abbreviate = FALSE)),
  get_day(events),
  (function(x) {
    s <- as.character(x)
    paste0(
      toupper(substring(s, 1, 1)),
      substring(s, 2)
    )
  })(date_month_factor(events, labels = "fr", abbreviate = FALSE))
)
names(rcode) <- sprintf("R/%s.R", events)

mapply(
  FUN = writeLines,
  text = rcode,
  con = names(rcode)
)
