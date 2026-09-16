library(dplyr)
library(tibble)
library(purrr)
library(readr)
library(tidyverse)
library(tidyr)
library(stringr)
library(arrow)
library(survival)

antibiotics <- c(
  "amoxicillin",
  "amox_clavulanic_acid",
  "cefalexin",
  "trimethoprim",
  "trim_sulfamethoxazole",
  "fluoroquinolones"
)

risk_vars <- c(
  "amoxicillin_risk_tendinitis",
  "amox_clavulanic_acid_risk_tendinitis",
  "cefalexin_risk_tendinitis",
  "trimethoprim_risk_tendinitis",
  "trim_sulfamethoxazole_risk_tendinitis",
  "fluoroquinolones_risk_tendinitis"
)

reference_vars <- c(
  "amoxicillin_reference_tendinitis",
  "amox_clavulanic_acid_reference_tendinitis",
  "cefalexin_reference_tendinitis",
  "trimethoprim_reference_tendinitis",
  "trim_sulfamethoxazole_reference_tendinitis",
  "fluoroquinolones_reference_tendinitis"
)

#tendinitis_case tells us if they are the cases or matched controls

df <- read_feather("output/matched_combined_tendinitis.arrow") %>% 
mutate(tendinitis_case = if_else(tendinitis_case == "T", "case", "control", missing = "control"))

#Shift to long format - one row per time point (risk vs reference) - currently only set up for fluoroquinolones, but to be expanded to other antibiotics

df_long <- df %>%
  select(patient_id, tendinitis_case, fluoroquinolones_risk_tendinitis, fluoroquinolones_reference_tendinitis) %>%
  pivot_longer(
    cols = c(fluoroquinolones_risk_tendinitis, fluoroquinolones_reference_tendinitis),
    names_to = "period_name",
    values_to = "Exposed"
  ) %>%
  mutate(
    Time = if_else(period_name == "fluoroquinolones_risk_tendinitis", 1, 0),
    Group = tendinitis_case  # however your case/control flag is coded — make sure it's 0/1
  ) %>%
  select(patient_id, Group, Time, Exposed)

  head(df_long)
  head(df_long_sixabx)

  exposure_cols <- c(risk_vars, reference_vars)

df_long_sixabx <- ctc_plus_controls %>%
  select(patient_id, tendinitis_case, all_of(exposure_cols)) %>%
  pivot_longer(
    cols = all_of(exposure_cols),
    names_to = c("antibiotic", "period_name"),
    names_pattern = "^(.*)_(risk|reference)_tendinitis$",
    values_to = "E"
  ) %>%
  mutate(
    T = if_else(period_name == "risk", 1, 0),
    G = if_else(tendinitis_case == "case", 1, 0)
  ) %>%
  select(patient_id, antibiotic, G, T, E)

model <- clogit(Time ~ Exposed + Exposed:Group + strata(patient_id), data = df_long)
summary(model)