library(readr)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)

ctc_cases_data <- readr::read_csv("output/ctc_data_cases_tendinitis.csv.gz")
ctc_potential_controls <- readr::read_csv("output/ctc_data_potential_controls_tendinitis.csv.gz")
ctc_potential_controls_withindex <- readr::read_csv("output/ctc_data_ptnl_controls_indexappended.csv.gz")
ctc_potential_controls_withindex_and_age <- readr::read_csv("output/ctc_data_potentialcontrols_withindexdates_andages_tendinitis.csv.gz")

## Make a recreatable list of abx risk/ref

abx_risk_ref_periods <- c(
  "amoxicillin_risk_tendinitis",
  "amoxicillin_reference_tendinitis",
  "amox_clavulanic_acid_risk_tendinitis",
  "amox_clavulanic_acid_reference_tendinitis",
  "cefalexin_risk_tendinitis",
  "cefalexin_reference_tendinitis",
  "trimethoprim_risk_tendinitis",
  "trimethoprim_reference_tendinitis",
  "trim_sulfamethoxazole_risk_tendinitis",
  "trim_sulfamethoxazole_reference_tendinitis",
  "fluoroquinolones_risk_tendinitis",
  "fluoroquinolones_reference_tendinitis"
)

# Age groups
age_summary <- ctc_cases_data %>%
  mutate(
    age_group = cut(
      age,
      breaks = c(-Inf, 30, 40, 50, 60, 70, 80, 90, 100, Inf),
      right = FALSE,
      labels = c(
        "<30",
        "30-39",
        "40-49",
        "50-59",
        "60-69",
        "70-79",
        "80-89",
        "90-99",
        "100+"
      )
    )
  ) %>%
  count(age_group, name = "count") %>%
  mutate(
    variable = "Age",
    category = as.character(age_group)
  ) %>%
  select(variable, category, count)

# Sex
sex_summary <- ctc_cases_data %>%
  count(sex, name = "count") %>%
  mutate(
    variable = "Sex",
    category = as.character(sex)
  ) %>%
  select(variable, category, count)

#Index date

index_date_summary <- ctc_cases_data %>%
  mutate(
    index_month = floor_date(index_date, unit = "month")
  ) %>%
  count(index_month, name = "count") %>%
  mutate(
    variable = "Index Month",
    category = as.character(index_month)
  ) %>%
  select(variable, category, count)

#Abx exposures

abx_exposures <- ctc_cases_data %>%
  summarise(
    across(abx_risk_ref_periods,
      ~sum(.x, na.rm = TRUE)
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "count"
  ) %>%
  mutate(category = "abx_exp") %>%
  select(variable, category, count)

# Total
total_summary <- ctc_cases_data %>%
  summarise(
    variable = "Total",
    category = "Cases",
    count = n()
  )


# Combine
summary_table <- bind_rows(
  total_summary,
  sex_summary,
  age_summary,
  abx_exposures,
  index_date_summary
)

#Check distribution index dates

  ggplot(index_date_summary, aes(x = index_month, y = n)) +
  geom_line() +
  labs(
    x = "Index date",
    y = "Number of cases"
  ) +
  theme_minimal()


ctc_potential_controls %>%
summarise(count = n())

ctc_potential_controls %>%
group_by(sex) %>%
summarise(count = n())

ctc_potential_controls_withindex_and_age %>%
summarise(count = n())

ctc_potential_controls_withindex_and_age %>%
group_by(sex) %>%
summarise(count = n())

ctc_potential_controls_withindex %>%
summarise(count = n())

ctc_potential_controls_withindex %>%
group_by(sex) %>%
summarise(count = n())