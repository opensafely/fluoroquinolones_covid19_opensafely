library(dplyr)
library(tibble)
library(purrr)

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
  
  b <- cc %>%
    filter(
      .data[[risk_var]] == TRUE,
      .data[[reference_var]] == FALSE
    ) %>%
    pull(n)
  
  c <- cc %>%
    filter(
      .data[[risk_var]] == FALSE,
      .data[[reference_var]] == TRUE
    ) %>%
    pull(n)
  
  # Calculate OR
  or <- b / c
  
  # Calculate 95% CI on log scale
  log_or <- log(or)
  
  se_log_or <- sqrt(1 / b + 1 / c)
  
  lower <- exp(log_or - 1.96 * se_log_or)
  
  upper <- exp(log_or + 1.96 * se_log_or)
  
  # Return results
  tibble(
    antibiotic = antibiotic,
    b = b,
    c = c,
    OR = or,
    lower_95CI = lower,
    upper_95CI = upper
  )
}


# Run for all six antibiotics
cc_results <- map_dfr(
  antibiotics,
  ~ calculate_cc_or(ctc_cases_data, .x)
)

cc_results