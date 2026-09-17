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

#tendinitis_case tells us if they are the cases or matched controls

df <- read_feather("output/matched_combined_tendinitis.arrow") %>% 
mutate(tendinitis_case = if_else(tendinitis_case == "T", "case", "control", missing = "control")) %>%
mutate(across(all_of(exposure_cols),~case_when(
  . == "T" ~ 1, 
  . == "F" ~ 0, 
  TRUE ~ NA_real_)
  ))

#Long format pairwise for risk and reference periods - Split out for the six antibiotics, so we can run the model for each antibiotic separately

 df_long_sixabx <-df %>%
 select(
    patient_id,
    tendinitis_case,
    all_of(exposure_cols)
  ) %>%

  # Stack risk and reference periods into rows
  pivot_longer(
    cols = all_of(exposure_cols),
    names_to = c("antibiotic", "period_name"),
    names_pattern = "^(.*)_(risk|reference)_tendinitis$",
    values_to = "Exposed"
  ) %>%

  # Turn the six antibiotics into six separate columns
  pivot_wider(
    names_from = antibiotic,
    values_from = Exposed
  ) %>%

  mutate(
    Time_risk_ref = if_else(period_name == "risk", 1, 0),
    Group_case_control = if_else(tendinitis_case == "case", 1, 0)
  ) %>%

  select(
    patient_id,
    Time_risk_ref,
    Group_case_control,
    all_of(antibiotics)
  )

# Want to estimate the OR for antibiotic exposure in risk vs reference period for those with tendinitis/neuropathy, 
# with a control of exposure in risk vs reference period in those without tendinitis to account for temporal changes in prescribing
# Variables - Time - risk = 1, reference = 0
# Exposed - 1 = exposed, 0 = not exposed
# Group - cases = 1, controls (for time trend) = 0

model_fq <- clogit(Time_risk_ref ~ fluoroquinolones + fluoroquinolones:Group_case_control + strata(patient_id), data = df_long_sixabx)
summary(model_fq)

#Save output

sink("output/ctc_fq_only_ctccomplete.txt")

  cat("\n\n========================================\n")
  cat("Antibiotic: fluoroquinolones_outsideloop - model to compare\n")
  cat("========================================\n\n")

  print(model_fq)

sink()

#Loop and run across all six antibiotics

models <- setNames(
  lapply(antibiotics, function(abx) {

    formula <- as.formula(
      paste0(
        "Time_risk_ref ~ ",
        abx,
        " + ",
        abx,
        ":Group_case_control + strata(patient_id)"
      )
    )

    clogit(
      formula,
      data = df_long_sixabx
    )
  }),
  antibiotics
)

#Generate summary

six_models <- lapply(models, summary)

#Save output

sink("output/ctc_six_models_summaries.txt")

for (abx in names(six_models)) {

  cat("\n\n========================================\n")
  cat("Antibiotic:", abx, "\n")
  cat("========================================\n\n")

  print(six_models[[abx]])
}

sink()