# A single place to store all the variables used in the analysis.
# This is useful for keeping track of which variables are used in which analysis, and for making it easy to change variable names if needed.

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

exposure_cols <- (c(risk_vars, reference_vars))