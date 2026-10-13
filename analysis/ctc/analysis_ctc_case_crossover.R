library(dplyr)
library(tibble)
library(purrr)
library(readr)
library(tidyverse)
library(tidyr)
library(stringr)
library(arrow)

#Read in combined data and use these

tendinitis_combo <- read_feather("output/matched_combined_tendinitis.arrow") %>%
mutate(event = "tendinitis")
neuropathy_combo <- read_feather("output/matched_combined_neuropathy.arrow") %>%
mutate(event = "neuropathy")

#Make case status text rather than number and correct arrow conversion of True to T

ctc_cases_controls_combo <- bind_rows(tendinitis_combo, neuropathy_combo) %>%
mutate(case = case_when(
  case == 1 ~ "Case",
  case == 0 ~ "Control",
  TRUE ~ NA_character_  
)) 

casestatus <- c(
  "Case", 
  "Control"
  )

outcomes <- c(
  "tendinitis",
  "neuropathy"
)

#Draw in defined variables/vectors from variables.R
source("analysis/R/variables.R")


# Collapse down to single risk/ref antibiotics code (and keep indicator of neuropathy/tendinitis and case/control as separate column)

for (ab in antibiotics) {
  
  risk_tendinitis <- paste0(ab, "_risk_tendinitis")
  risk_neuropathy <- paste0(ab, "_risk_neuropathy")
  
  ref_tendinitis <- paste0(ab, "_reference_tendinitis")
  ref_neuropathy <- paste0(ab, "_reference_neuropathy")
  
  risk_new <- paste0(ab, "_risk")
  ref_new <- paste0(ab, "_reference")
  
  ctc_cases_controls_combo[[risk_new]] <- ifelse(
    ctc_cases_controls_combo$event == "tendinitis",
    ctc_cases_controls_combo[[risk_tendinitis]],
    ifelse(
      ctc_cases_controls_combo$event == "neuropathy",
      ctc_cases_controls_combo[[risk_neuropathy]],
      NA
    )
  )
  
  ctc_cases_controls_combo[[ref_new]] <- ifelse(
    ctc_cases_controls_combo$event == "tendinitis",
    ctc_cases_controls_combo[[ref_tendinitis]],
    ifelse(
      ctc_cases_controls_combo$event == "neuropathy",
      ctc_cases_controls_combo[[ref_neuropathy]],
      NA
    )
  )
}

#Sanity check for data before proceeding

ctc_cases_controls_combo %>% 
group_by(event, case, amoxicillin_risk_tendinitis, amoxicillin_risk_neuropathy) %>%
summarise(count = n())

#Now convert T/F to TRUE and FLASE (Arrow vs csv - need TRUE for counting further down)

ctc_cases_controls_combo <- ctc_cases_controls_combo %>% 
mutate(
  across(
    all_of(c(risk_vars, reference_vars)),
    ~ case_when(
      .x == "T" ~ TRUE,
      .x == "F" ~ FALSE,
      TRUE ~ NA
    )
  )
)

#Save this formatted data

colnames(ctc_cases_controls_combo)

readr::write_csv(ctc_cases_controls_combo, here::here("output", "dataset_ctc_cases_controls_neuroptendinitis.csv"))

# Function to calculate case-crossover OR and 95% CI - separately by antibiotic, outcome and case/timetrend(control) status.

calculate_cc_or_casesandcontrols <- function(data, antibiotic, outcome, case_control) {
  
  risk_var <- paste0(antibiotic, "_risk")
  reference_var <- paste0(antibiotic, "_reference")

  analysis_data <- data %>%
    filter(event == outcome, case == case_control)

  exp_risk_unexp_ref <- sum(
    analysis_data[[risk_var]] == TRUE &
    analysis_data[[reference_var]] == FALSE,
    na.rm = TRUE
  )
  
  unexp_risk_exp_ref <- sum(
    analysis_data[[risk_var]] == FALSE &
    analysis_data[[reference_var]] == TRUE,
    na.rm = TRUE
  )
  
  # Calculate OR
  or <- exp_risk_unexp_ref / unexp_risk_exp_ref
  
  # Calculate 95% CI on log scale
  log_or <- log(or)
  
  se_log_or <- sqrt(1 / exp_risk_unexp_ref + 1 / unexp_risk_exp_ref)
  
  lower <- exp(log_or - 1.96 * se_log_or)
  
  upper <- exp(log_or + 1.96 * se_log_or)
  
  # Return results
  tibble(
    outcome = outcome,
    case_control = case_control,
    antibiotic = antibiotic,
    exp_risk_unexp_ref = exp_risk_unexp_ref,
    unexp_risk_exp_ref = unexp_risk_exp_ref,
    OR = or,
    lower_95CI = lower,
    upper_95CI = upper
  ) 
}

## Run function for each level of outcome, antibiotic, case/timetrend status

cc_results_casesandcontrols <- expand.grid(
  antibiotic = antibiotics,
  outcome = outcomes,
  case_control = casestatus,
  stringsAsFactors = FALSE
) %>%
  purrr::pmap_dfr(function(antibiotic, outcome, case_control) {
    calculate_cc_or_casesandcontrols(
      data = ctc_cases_controls_combo,
      antibiotic = antibiotic,
      outcome = outcome,
      case_control = case_control
    )
  }) %>%
  mutate(
    across(
      where(is.numeric),
        ~ round(.x, 2)
    )
  ) %>%
  mutate(analysis = "raw")

cc_results_casesandcontrols

# Now look at excluding anyone who received the other antibiotic in either the risk or reference period. Riskvars defined in variables.R

risk_gt1 <- sum(rowSums(ctc_cases_controls_combo[risk_vars]) > 1)

reference_gt1 <- sum(rowSums(ctc_cases_controls_combo[reference_vars]) > 1)

risk_gt1_tendinitis <- sum(rowSums((ctc_cases_controls_combo %>% 
dplyr::filter(event == "tendinitis"))[risk_vars]) > 1)

cat(
  "There were", risk_gt1, "people with >1 antibiotic in the risk period and",
  reference_gt1, "people with >1 antibiotic in the reference period.\n"
)

ctc_cases_controls_combo_single_abx <- ctc_cases_controls_combo %>%
  filter(
    rowSums(across(all_of(risk_vars))) <= 1,
    rowSums(across(all_of(reference_vars))) <= 1
  )

#Run analysis for these

cc_results_singleabx_casecontrols <- expand.grid(
  antibiotic = antibiotics,
  outcome = outcomes,
  case_control = casestatus,
  stringsAsFactors = FALSE
) %>%
purrr::pmap_dfr(function(antibiotic, outcome, case_control){
  calculate_cc_or_casesandcontrols(
    data = ctc_cases_controls_combo_single_abx,
    antibiotic = antibiotic,
    outcome = outcome,
    case_control = case_control
  )
}) %>%
  mutate(
    across(
      where(is.numeric),
        ~ round(.x, 2)
    )
  ) %>%
mutate(analysis = "single_abx_risk_ref")

cc_results_singleabx_casecontrols

# Join df together and tidy for plotting

joined_analyses <-  cc_results_casesandcontrols %>%
bind_rows(cc_results_singleabx_casecontrols) %>% 
mutate(
    antibiotic = recode(
      antibiotic,
      "amoxicillin" = "Amoxicillin",
      "amox_clavulanic_acid" = "Amoxicillin/clavulanic acid",
      "cefalexin" = "Cefalexin",
      "trimethoprim" = "Trimethoprim",
      "trim_sulfamethoxazole" = "Trimethoprim/sulfamethoxazole",
      "fluoroquinolones" = "Fluoroquinolones"
    ),
    antibiotic = factor(
      antibiotic,
      levels = c(
        "Fluoroquinolones",
        "Amoxicillin",
        "Amoxicillin/clavulanic acid",
        "Cefalexin",
        "Trimethoprim",
        "Trimethoprim/sulfamethoxazole"
      )
    )
  )

#Create location for work to go and save table
dir.create("output/ctc", recursive = TRUE, showWarnings = FALSE)

joined_analyses %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/vanilla_case_crossover_output.md")


#Plot - simple cc first

basic_cc_plot <- ggplot((joined_analyses %>% 
  filter(analysis == "single_abx_risk_ref", case_control == "Case")), 
  aes(x = OR, y = antibiotic)) +
  geom_errorbar(
    aes(xmin = lower_95CI, xmax = upper_95CI),
    orientation = "y",
    width = 0.5
  ) +
  facet_wrap(~outcome) +
  geom_point(size = 5) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  scale_x_log10() +
  labs(
    x = "Odds ratio (95% CI)",
    y = "Antibiotic"
  ) +
  ggtitle("Basic Case Crossover Analysis - Cases - single abx in risk/ref") +
  theme_classic()

basic_cc_plot

ggsave(plot = basic_cc_plot,
filename = "basic_cc_plot.png",
path = here::here("output/ctc")
)

#Do one for time trend also

timetrend_cc_plot <- ggplot((joined_analyses %>% 
  filter(analysis == "single_abx_risk_ref", case_control == "Control")), 
  aes(x = OR, y = antibiotic)) +
  geom_errorbar(
    aes(xmin = lower_95CI, xmax = upper_95CI),
    orientation = "y",
    width = 0.5
  ) +
  facet_wrap(~outcome) +
  geom_point(size = 5) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  scale_x_log10() +
  labs(
    x = "Odds ratio (95% CI)",
    y = "Antibiotic"
  ) +
  ggtitle("Time Trend Case Crossover Analysis - Controls - single abx in risk/ref") +
  theme_classic()

  timetrend_cc_plot

  ggsave(plot = timetrend_cc_plot,
  filename = "timetrend_cc_plot.png",
  path = here::here("output/ctc")
  )
