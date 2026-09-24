library(dplyr)
library(tibble)
library(purrr)
library(readr)
library(tidyverse)
library(tidyr)
library(stringr)
library(arrow)

ctc_cases_data_tendinitis <- readr::read_csv("output/ctc_data_cases_tendinitis.csv.gz") %>%
mutate(event = "tendinitis")
ctc_cases_data_neuropathy <- readr::read_csv("output/ctc_data_cases_neuropathy.csv.gz") %>%
mutate(event = "neuropathy")

outcomes <- c(
  "tendinitis",
  "neuropathy"
)

ctc_cases_data <- bind_rows(ctc_cases_data_tendinitis, ctc_cases_data_neuropathy)

#Draw in defined variables/vectors from variables.R
source("analysis/R/variables.R")

#Collapse down the risk/reference to one shared column

for (ab in antibiotics) {
  
  risk_tendinitis <- paste0(ab, "_risk_tendinitis")
  risk_neuropathy <- paste0(ab, "_risk_neuropathy")
  
  ref_tendinitis <- paste0(ab, "_reference_tendinitis")
  ref_neuropathy <- paste0(ab, "_reference_neuropathy")
  
  risk_new <- paste0(ab, "_risk")
  ref_new <- paste0(ab, "_reference")
  
  ctc_cases_data[[risk_new]] <- ifelse(
    ctc_cases_data$event == "tendinitis",
    ctc_cases_data[[risk_tendinitis]],
    ifelse(
      ctc_cases_data$event == "neuropathy",
      ctc_cases_data[[risk_neuropathy]],
      NA
    )
  )
  
  ctc_cases_data[[ref_new]] <- ifelse(
    ctc_cases_data$event == "tendinitis",
    ctc_cases_data[[ref_tendinitis]],
    ifelse(
      ctc_cases_data$event == "neuropathy",
      ctc_cases_data[[ref_neuropathy]],
      NA
    )
  )
}

#Sanity check before calculating - just use amoxicillin to check

ctc_cases_data %>% 
group_by(event, tendinitis_case, neuropathy_case, amoxicillin_risk_tendinitis, amoxicillin_risk_neuropathy) %>%
summarise(count = n())

# Function to calculate case-crossover OR and 95% CI
calculate_cc_or <- function(data, antibiotic, outcome) {
  
  risk_var <- paste0(antibiotic, "_risk")
  reference_var <- paste0(antibiotic, "_reference")

  analysis_data <- data %>%
    filter(event == outcome)
  
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
    antibiotic = antibiotic,
    exp_risk_unexp_ref = exp_risk_unexp_ref,
    unexp_risk_exp_ref = unexp_risk_exp_ref,
    OR = or,
    lower_95CI = lower,
    upper_95CI = upper
  ) 
}

# Run for all six antibiotics and two outcome combos

cc_results <- expand.grid(
  antibiotic = antibiotics,
  outcome = outcomes,
  stringsAsFactors = FALSE
) %>%
  purrr::pmap_dfr(function(antibiotic, outcome) {
    calculate_cc_or(
      data = ctc_cases_data,
      antibiotic = antibiotic,
      outcome = outcome
    )
  }) %>%
  mutate(
    across(
      where(is.numeric),
        ~ round(.x, 2)
    )
  ) %>%
  mutate(analysis = "raw")

  cc_results


# Now look at excluding anyone who received the other antibiotic in either the risk or reference period. Riskvars defined in variables.R

risk_gt1 <- sum(rowSums(ctc_cases_data[risk_vars]) > 1)

reference_gt1 <- sum(rowSums(ctc_cases_data[reference_vars]) > 1)

risk_gt1_tendinitis <- sum(rowSums((ctc_cases_data %>% 
dplyr::filter(event == "tendinitis"))[risk_vars]) > 1)

cat(
  "There were", risk_gt1, "people with >1 antibiotic in the risk period and",
  reference_gt1, "people with >1 antibiotic in the reference period.\n"
)

ctc_cases_data_single_abx <- ctc_cases_data %>%
  filter(
    rowSums(across(all_of(risk_vars))) <= 1,
    rowSums(across(all_of(reference_vars))) <= 1
  )

cc_results_singleabx <- expand.grid(
  antibiotic = antibiotics,
  outcome = outcomes,
  stringsAsFactors = FALSE
) %>%
purrr::pmap_dfr(function(antibiotic, outcome){
  calculate_cc_or(
    data = ctc_cases_data_single_abx,
    antibiotic = antibiotic,
    outcome = outcome
  )
}) %>%
  mutate(
    across(
      where(is.numeric),
        ~ round(.x, 2)
    )
  ) %>%
mutate(analysis = "single_abx_risk_ref")

cc_results_singleabx

# Join df together and tidy for plotting

joined_analyses <- cc_results %>%
bind_rows(cc_results_singleabx) %>% 
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


#Create location for work to go
dir.create("output/ctc", recursive = TRUE, showWarnings = FALSE)

joined_analyses %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/vanilla_case_crossover_output.md")

#Plot

basic_cc_plot <- ggplot((joined_analyses %>% 
  filter(analysis == "single_abx_risk_ref")), aes(x = OR, y = antibiotic)) +
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
  ggtitle("Basic Case Crossover Analysis - Tendinitis - only single abx in risk/ref") +
  theme_classic()

basic_cc_plot

ggsave(plot = basic_cc_plot,
filename = "basic_cc_plot.png",
path = here::here("output/ctc")
)

#Repeat this analysis for the controls - I think the arrow converts TRUE to T - got up to this point so to resume here

ctc_plus_controls <- read_feather("output/matched_combined_tendinitis.arrow") %>% 
mutate(tendinitis_case = if_else(tendinitis_case == "T", "case", "control", missing = "control")) %>%
mutate(
  across(all_of(c(risk_vars, reference_vars)), ~ case_when(
    .x == "T" ~ TRUE,
    .x == "F" ~ FALSE,
    TRUE ~ NA
  ))
)

ctc_results_timetrend <- map_dfr(
  antibiotics,
  ~ calculate_cc_or((ctc_plus_controls %>% filter(tendinitis_case == "control")), .x)
) %>%
  mutate(
    across(
      where(is.numeric),
        ~ round(.x, 2)
    )
  ) %>%
  mutate(analysis = "control_timetrend")

ctc_results_timetrend %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/timetrend_case_crossover_output.md")