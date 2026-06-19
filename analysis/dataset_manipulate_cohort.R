library(tidyverse)
library(readr)
library(survival)
library(dplyr)
library(lubridate)

#Ensure data read in in correct format

df <- readr::read_csv("output/dataset.csv.gz", col_types = readr::cols(
    first_tendinitis_diagnosis_date = col_date(format = "%Y-%m-%d"),
    first_neuropathy_diagnosis_date = col_date(format = "%Y-%m-%d"),
    date_cohort_prescription = col_date(format = "%Y-%m-%d"),
    date_of_death = col_date(format = "%Y-%m-%d"),
    fluoroquinolone_exp = col_logical(),
    imd_decile = col_character(),
    last_bmi = col_double()
    ),
  na = c("", "NA", "na")
 ) %>%
    mutate(
    imd_decile = if_else(imd_decile %in% as.character(1:10), imd_decile, NA_character_),
    imd_decile = factor(imd_decile, levels = as.character(1:10)), #Clean imd_decile: set invalid values to NA, then convert to factor
  bmi_cat = cut(last_bmi,
                       breaks = c(-Inf, 18.5, 25, 30, Inf),
                       labels = c("Underweight", "Normal", "Overweight", "Obese"),
                       right = FALSE),
  bmi_cat = factor(bmi_cat)
  )

df <- df %>%
mutate(
    # Exclude tendinitis diagnoses that occur before prescription
    tendinitis_post_rx = if_else(
      !is.na(first_tendinitis_diagnosis_date) & first_tendinitis_diagnosis_date > date_cohort_prescription, #Important use > not >= here to exclude same day events
      first_tendinitis_diagnosis_date,
      as.Date(NA) #Na if not meeting logic
    ),
# Calculate 30-day censoring date
    censor_30d = date_cohort_prescription + days(3000),  #***CAUTION SET ARTIFICALLY HIGH TO HELP WITH BUILDING MODELS - NEED TO PULL BACK 
# Compute the censoring date: the earliest of event, death, or 30-day censor
    censor_date_tendinitis = pmin(tendinitis_post_rx, date_of_death, censor_30d, na.rm = TRUE),
      # Create event indicator: 1 if event occurred on or before censoring, 0 otherwise
    event_tendinitis = if_else(
      !is.na( tendinitis_post_rx) & #Those with a tendinitis event after prescription
       tendinitis_post_rx <= censor_date_tendinitis, #Those where it did not occur after censorship
      1, 0
    ),
    # Time from entry to censoring (in days)
    time_tendinitis = as.numeric(difftime(censor_date_tendinitis, date_cohort_prescription, units = "days"))
) %>% #Now for neuropathy
mutate(
    # Exclude  diagnoses that occur before prescription
    neuropathy_post_rx = if_else(
      !is.na(first_neuropathy_diagnosis_date) & first_neuropathy_diagnosis_date > date_cohort_prescription, #Important use > not >= here to exclude same day events
      first_neuropathy_diagnosis_date,
      as.Date(NA) #Na if not meeting logic
    ),
# Compute the censoring date: the earliest of event, death, or 30-day censor
    censor_date_neuropathy = pmin(neuropathy_post_rx, date_of_death, censor_30d, na.rm = TRUE),
      # Create event indicator: 1 if event occurred on or before censoring, 0 otherwise
    event_neuropathy = if_else(
      !is.na(neuropathy_post_rx) & #Those with a tendinitis event after prescription
       neuropathy_post_rx <= censor_date_neuropathy, #Those where it did not occur after censorship
      1, 0
    ),
    # Time from entry to censoring (in days)
    time_neuropathy = as.numeric(difftime(censor_date_neuropathy, date_cohort_prescription, units = "days"))
)

readr::write_csv(df, here::here("output", "dataset_formatted_cohort.csv"))

#Double check number of event

if (!dir.exists("output/cohort")) {
  dir.create("output/cohort", recursive = TRUE)
}

df %>%
group_by(fluoroquinolone_exp) %>%
  summarise(count_event = sum(event_tendinitis == 1, na.rm = TRUE)) %>% 
  knitr::kable(format = "markdown") %>%
  writeLines("output/cohort/n_events.md")



#Look at missing data
#Will need to add smoking, n gp appts

baseline_vars <- c("sex", "age", "last_bmi", "ethnicity16", "imd_decile", "harmful_alcohol",
"n_hosp_appt_6m",
"has_diabetes", "has_had_cancer", "has_chronic_liver_disease", "has_chronic_resp_disease",
"has_dementia", "has_hiv", "has_heart_failure", "has_hemiplegia", "has_multiple_sclerosis", "has_rheumatoid_arthritis", "has_solid_organ_transplant",              
"has_stroke_tia", "has_aaa", "has_ckd", "has_coronary_hd", "has_hypertension", "has_peptic_ulcer", "has_pvd",  
"corticosteroid_60d_before_abx","drug_linked_to_neuropathy_60d_before_abx" )  

na_count<- df %>%
group_by(fluoroquinolone_exp) %>%
summarise(across(all_of(baseline_vars),
                        ~sum(is.na(.)))) %>%
 pivot_longer(
    cols = -fluoroquinolone_exp,
    names_to = "variable",
    values_to = "na_count"
  ) %>%
  mutate(fluoroquinolone_exp = ifelse(fluoroquinolone_exp == 1, "Yes", "No")) %>%
  pivot_wider(
    names_from = fluoroquinolone_exp,
    values_from = na_count,
    values_fill = 0
  ) 
  
  na_count$variable <- factor(na_count$variable, levels = baseline_vars)

  na_count %>%
  arrange(variable) %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/cohort/missingdata_count_df.md")