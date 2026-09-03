library(dplyr)
library(tibble)
library(purrr)
library(readr)
library(tidyverse)
library(tidyr)
library(stringr)

ctc_cases_data <- readr::read_csv("output/ctc_data_cases_tendinitis.csv.gz")

antibiotics <- c(
  "amoxicillin",
  "amox_clavulanic_acid",
  "cefalexin",
  "trimethoprim",
  "trim_sulfamethoxazole",
  "fluoroquinolones"
)

# Function to calculate case-crossover OR and 95% CI
calculate_cc_or <- function(data, antibiotic) {
  
  risk_var <- paste0(antibiotic, "_risk_tendinitis")
  reference_var <- paste0(antibiotic, "_reference_tendinitis")
  
  cc <- data %>%
    count(
      .data[[risk_var]],
      .data[[reference_var]]
    )
  
  exp_risk_unexp_ref <- cc %>%
    filter(
      .data[[risk_var]] == TRUE,
      .data[[reference_var]] == FALSE
    ) %>%
    pull(n)
  
  unexp_risk_exp_ref <- cc %>%
    filter(
      .data[[risk_var]] == FALSE,
      .data[[reference_var]] == TRUE
    ) %>%
    pull(n)
  
  # Calculate OR
  or <- exp_risk_unexp_ref / unexp_risk_exp_ref
  
  # Calculate 95% CI on log scale
  log_or <- log(or)
  
  se_log_or <- sqrt(1 / exp_risk_unexp_ref + 1 / unexp_risk_exp_ref)
  
  lower <- exp(log_or - 1.96 * se_log_or)
  
  upper <- exp(log_or + 1.96 * se_log_or)
  
  # Return results
  tibble(
    antibiotic = antibiotic,
    exp_risk_unexp_ref = exp_risk_unexp_ref,
    unexp_risk_exp_ref = unexp_risk_exp_ref,
    OR = or,
    lower_95CI = lower,
    upper_95CI = upper
  ) 
}


# Run for all six antibiotics
cc_results <- map_dfr(
  antibiotics,
  ~ calculate_cc_or(ctc_cases_data, .x)
) %>%
  mutate(
    across(
      where(is.numeric),
        ~ round(.x, 2)
    )
  )  

#Create location for work to go
dir.create("output/ctc", recursive = TRUE, showWarnings = FALSE)

cc_results %>%
  knitr::kable(format = "markdown") %>%
  writeLines("output/ctc/vanilla_case_crossover_output.md")

cc_results