######################################

# This script provides the formal specification of the data that will be extracted from
# the OpenSAFELY database for the case-time-control analysis.

#Jack Stanley

#opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py

#nb check https://docs.opensafely.org/case-control-studies/#background

######################################

from ehrql import create_dataset, codelist_from_csv, years, months, weeks, days, show
from ehrql.tables.tpp import patients, medications, practice_registrations, addresses, clinical_events, apcs, ons_deaths
from codelists import *

dataset = create_dataset()

start_date = "2010-12-01" ##TBC
end_date = "2024-08-01"  ##TBC

#Exposure codes

amoxicillin_codes = codelist_from_csv("codelists/opensafely-amoxicillin-oral.csv", column = "code")
amox_clavulanicacid_codes = codelist_from_csv("codelists/opensafely-co-amoxiclav-oral.csv", column = "code")
cefalexin_codes = codelist_from_csv("codelists/opensafely-cefalexin-oral.csv", column = "code")
trimethoprim_codes = codelist_from_csv("codelists/opensafely-trimethoprim.csv", column = "code")
trim_sulfa_codes = codelist_from_csv("codelists/user-jacklsbrist-trimethoprimsulfamethoxazole-dmd.csv", column = "code")

fluoroquinolone_codes = codelist_from_csv("codelists/user-jacklsbrist-fluoroquinolones-dmd.csv", column = "code")

all_abx_codes = amoxicillin_codes + amox_clavulanicacid_codes + cefalexin_codes + trimethoprim_codes + trim_sulfa_codes + fluoroquinolone_codes

#Outcome codes

tendinitis_codes = codelist_from_csv("codelists/user-jacklsbrist-tendinitis.csv", column = "code")
neuropathy_newdx_codes = codelist_from_csv("codelists/user-jacklsbrist-peripheral-neuropathy.csv", column = "code")

combo_outcome_codes = tendinitis_codes + neuropathy_newdx_codes

        #Include just cases after the start date

tendinitis_case_date = clinical_events.where(clinical_events.snomedct_code.is_in(tendinitis_codes )
).where(
    clinical_events.date.is_after(start_date)
).where(clinical_events.date.is_before(end_date)
).sort_by(
        clinical_events.date
).first_for_patient().date

    #Registration 1y before case status

has_registration_1y_before_tendinitis =  (
    practice_registrations.where(practice_registrations.start_date <= (tendinitis_case_date - years(1)))
    .exists_for_patient()
)

#Exclusion criteria - those with prior tendinitis/neuropathy

prior_tendinitis = clinical_events.where(
        clinical_events.snomedct_code.is_in(tendinitis_codes) #Exclude those with pre-existing diagnoses
).where(
        clinical_events.date.is_on_or_before(start_date)
).exists_for_patient()

#Exclusion criteria - drug allergy to those 

#Dataset definition

dataset.define_population(
     (patients.exists_for_patient()) &
     tendinitis_case_date.is_not_null() &
     has_registration_1y_before_tendinitis &
    ~(prior_tendinitis) 
    )


dataset.configure_dummy_data(population_size=100000)

#Case status


dataset.tendinitis_case = tendinitis_case_date.is_not_null()

dataset.sex = patients.sex
dataset.age = patients.age_on(tendinitis_case_date) 
dataset.index_date = tendinitis_case_date

#Look for exposure in risk window

        #abx code dictionary for use in functions below
antibiotic_codelists_dmd = {
        "amoxicillin": amoxicillin_codes,
        "amox_clavulanic_acid": amox_clavulanicacid_codes,
        "cefalexin":cefalexin_codes,
        "trimethoprim": trimethoprim_codes,
        "trim_sulfamethoxazole":trim_sulfa_codes,

        "fluoroquinolones": fluoroquinolone_codes
    
}

# Define time windows for each period label
tendinitis_periods = {
    "risk": (days(30), days(1)),
    "reference": (days(180), days(151))
}


# Loop over antibiotics and periods
for antibiotic, codelist in antibiotic_codelists_dmd.items():
    for period_label, (start_offset, end_offset) in tendinitis_periods.items():
                setattr(
                        dataset,
                        f"{antibiotic}_{period_label}_tendinitis",
                         medications.where(medications.dmd_code.is_in(codelist))
                         .where(
                          medications.date.is_on_or_between(
                                        tendinitis_case_date - start_offset,
                                        tendinitis_case_date - end_offset
                )
            )
            .exists_for_patient()
        )

