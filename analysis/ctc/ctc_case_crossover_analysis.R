library(dplyr)
library(tibble)
library(purrr)
library(readr)
library(tidyverse)
library(tidyr)
library(stringr)

ctc_cases_data <- readr::read_csv("output/ctc_data_cases_tendinitis.csv.gz")

colnames(ctc_cases_data)

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

# Function to calculate case-crossover OR and 95% CI
calculate_cc_or <- function(data, antibiotic) {
  
  risk_var <- paste0(antibiotic, "_risk_tendinitis")
  reference_var <- paste0(antibiotic, "_reference_tendinitis")
  
  cc <- data %>%
    count(
      .data[[risk_var]],
      .data[[reference_var]]
    )
  
  exp_risk_unexp_ref <- sum(
    data[[risk_var]] == TRUE &
    data[[reference_var]] == FALSE,
    na.rm = TRUE
  )
  
  unexp_risk_exp_ref <- sum(
    data[[risk_var]] == FALSE &
    data[[reference_var]] == TRUE,
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
  ) %>%
  mutate(analysis = "raw")

# Now look at excluding anyone who received the other antibiotic in either the risk or reference period

risk_gt1 <- sum(rowSums(ctc_cases_data[risk_vars]) > 1)

reference_gt1 <- sum(rowSums(ctc_cases_data[reference_vars]) > 1)

cat(
  "There were", risk_gt1, "people with >1 antibiotic in the risk period and",
  reference_gt1, "people with >1 antibiotic in the reference period.\n"
)

ctc_cases_data_single_abx <- ctc_cases_data %>%
  filter(
    rowSums(across(all_of(risk_vars))) <= 1,
    rowSums(across(all_of(reference_vars))) <= 1
  )

cc_results_singleabx <- map_dfr(
  antibiotics,
  ~ calculate_cc_or(ctc_cases_data_single_abx, .x)
) %>%
  mutate(
    across(
      where(is.numeric),
        ~ round(.x, 2)
    )
  ) %>%
  mutate(analysis = "single_abx_risk_ref")

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
  geom_point(size = 5) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  scale_x_log10() +
  labs(
    x = "Odds ratio (95% CI)",
    y = "Antibiotic"
  ) +
  ggtitle("Basic Case Crossover Analysis - Tendinitis - only single abx in risk/ref")
  theme_classic()

basic_cc_plot

ggsave(plot = basic_cc_plot,
filename = "basic_cc_plot.png",
path = here::here("output/ctc")
)