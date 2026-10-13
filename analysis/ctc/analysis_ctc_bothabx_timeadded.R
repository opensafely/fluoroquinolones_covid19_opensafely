library(dplyr)
library(tibble)
library(purrr)
library(readr)
library(tidyverse)
library(tidyr)
library(stringr)
library(arrow)
library(survival)

#Draw in variables defined elsewhere

source("analysis/R/variables.R")

#Read in combined dataset (from earlier ctc_case_crossover file)

combined_data <- readr::read_csv("output/dataset_ctc_cases_controls_neuroptendinitis.csv",
col_types = cols(
    date_of_birth = col_date(),
    patient_table_sex = col_character()
  ))

colnames(combined_data)

#Long format pairwise for risk and reference periods - Split out for the six antibiotics, so we can run the model for each antibiotic separately
#case tells us if case or control and this is separated at level of tendinitis and neuropathy

 df_long_sixabx_twooutcomes <-combined_data %>%
 select(
    patient_id,
    case,
    event,
    all_of(exposure_cols)
  ) %>%

  # Stack risk and reference periods into rows
  pivot_longer(
    cols = all_of(exposure_cols),
    names_to = c("antibiotic", "period_name"),
    names_pattern = "^(.*)_(risk|reference)$",
    values_to = "Exposed"
  ) %>%

  # Turn the six antibiotics into six separate columns
  pivot_wider(
    names_from = antibiotic,
    values_from = Exposed
  ) %>%

    # Make single variable describing whether risk or reference
  mutate(
    Time_risk_ref = if_else(period_name == "risk", 1, 0),
    Group_case_controlegtimetrend = if_else(case == "Case", 1, 0)
  ) %>%

 # Convert antibiotic status to numeric
  mutate(
    across(
      all_of(antibiotics),
      ~ case_when(
        .x == TRUE  ~ 1,
        .x == FALSE ~ 0,
        TRUE        ~ NA_real_
      )
    )
  ) %>%

    # Keep only the data needed
  select(
    patient_id,
    event,
    Time_risk_ref,
    Group_case_controlegtimetrend,
    all_of(antibiotics)
  )


# Want to estimate the OR for antibiotic exposure in risk vs reference period for those with tendinitis/neuropathy, 
# with a control of exposure in risk vs reference period in those without tendinitis to account for temporal changes in prescribing
# Variables - Time - risk = 1, reference = 0
# Exposed - 1 = exposed, 0 = not exposed
# Group - cases = 1, controls (for time trend) = 0

#First time just to prove it works run the model with fq/tendinitis - this is the structure as per the Suisa paper 1995 - with risk/ref allocation
# antibiotic coef is for group 0. And we then get a separate output for group = 1 (ie cases) which is the interaction term of interest

head(df_long_sixabx_twooutcomes)

model_fq <- clogit(Time_risk_ref ~ fluoroquinolones + fluoroquinolones:Group_case_controlegtimetrend + strata(patient_id), 
data = (df_long_sixabx_twooutcomes %>% filter(event == "tendinitis")))
summary(model_fq)

#Save output

sink("output/ctc_fq_only_ctccomplete.txt")

  cat("\n\n========================================\n")
  cat("Antibiotic: fluoroquinolones_outsideloop - model to compare\n")
  cat("========================================\n\n")

  print(model_fq)

sink()

#Loop and run across all six antibiotics

outcomes <- c("tendinitis", "neuropathy")

outcome_models <- setNames(
  lapply(outcomes, function(outcome) {
    outcome_data <- df_long_sixabx_twooutcomes %>%
      filter(event == outcome)

    setNames(
      lapply(antibiotics, function(abx) {
        clogit(
          as.formula(paste0(
            "Time_risk_ref ~ ", abx,
            " + ", abx, ":Group_case_controlegtimetrend + strata(patient_id)"
          )),
          data = outcome_data
        )
      }),
      antibiotics
    )
  }),
  outcomes
)

# Generate summaries - nest by outcome then antibiotic
six_by_two_models <- lapply(outcome_models, function(models) {
  lapply(models, summary)
})


#Save output

sink("output/ctc_six_by_two_models_summaries.txt")

for (outcome in names(six_by_two_models)) {
  
  cat("\n\n########################################\n")
  cat("Outcome:", outcome, "\n")
  cat("########################################\n")
  
  for (abx in names(six_by_two_models)) {
    cat("\n\n========================================\n")
    cat("Antibiotic:", abx, "\n")
    cat("========================================\n\n")
    
    print(six_by_two_models[[abx]])
  }
}

sink()