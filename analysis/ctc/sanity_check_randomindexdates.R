library(data.table)
library(readr)
library(tidyverse)


controls <- readr::read_csv("/workspaces/fluoroquinolones_covid19_opensafely/output/ctc_data_ptnl_controls_indexappended.csv.gz")

#Check names right
colnames(controls)

#Convert to date
controls$index_date <- as.Date(controls$index_date)

#Check index date is read as a date
class(controls$index_date)

#Check range right
range(controls$index_date)

start_date <- as.Date("2010-12-01")
end_date <- as.Date("2024-08-01")

controls <- controls %>%
  mutate(
    year_index_date = as.integer(format(index_date, "%Y")),
    period_30day_index_date = floor(as.numeric(index_date - start_date) / 30) + 1
  )


controls %>%
  ggplot(aes(x = index_date)) +
  geom_histogram(
    binwidth = 30
  ) +
  labs(
    x = "Index date",
    y = "Number of controls"
  ) +
  ggtitle("Distribtution of random index_dates by 30 day period")

  controls %>%
  ggplot(aes(x = year_index_date)) +
  geom_histogram(
    binwidth = 1
  ) +
  labs(
    x = "Year",
    y = "Number of controls"
  ) +
  ggtitle("Distribtution of random index_dates by year")
