######################################

# This script provides the formal specification of the data that will be extracted from
# the OpenSAFELY database for the case-time-control analysis.

#Jack Stanley

#opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py

#nb check https://docs.opensafely.org/case-control-studies/#background

######################################

from ehrql import create_dataset, codelist_from_csv, years, months, weeks, days, show, case
from ehrql.tables.tpp import patients, medications, practice_registrations, addresses, clinical_events, apcs, ons_deaths
from codelists import *
from datetime import date, timedelta, datetime



#show(dataset) - how do I get show to work?

dataset = create_dataset()

start_date = "2010-12-01" ##TBC
end_date = "2024-08-01"  ##TBC


# #Outcome codes

tendinitis_codes = codelist_from_csv("codelists/user-jacklsbrist-tendinitis.csv", column = "code")
neuropathy_newdx_codes = codelist_from_csv("codelists/user-jacklsbrist-peripheral-neuropathy.csv", column = "code")

combo_outcome_codes = tendinitis_codes + neuropathy_newdx_codes

        #Include just cases after the start date

tendinitis_case_date = clinical_events.where(clinical_events.snomedct_code.is_in(tendinitis_codes )
).where(
    clinical_events.date.is_after(start_date)
).sort_by(
        clinical_events.date
).first_for_patient().date

    #Registration 1y before case status

has_registration_1y_before_start_date =  (
    practice_registrations.where(practice_registrations.start_date <= (start_date - years(1)))
    .except_where(practice_registrations.end_date < end_date)
    .exists_for_patient()
)

#Exclusion criteria - those with prior tendinitis/neuropathy

prior_tendinitis = clinical_events.where(
        clinical_events.snomedct_code.is_in(tendinitis_codes) #Exclude those with pre-existing diagnoses
).where(
        clinical_events.date.is_on_or_before(start_date)
).exists_for_patient()

#Exclusion criteria - drug allergy to those ?Is this necessary for the ctc?

#Dataset definition

dataset.define_population(
     (patients.exists_for_patient()) &
     has_registration_1y_before_start_date &
    ~(prior_tendinitis) 
    )

dataset.sex = patients.sex
dataset.configure_dummy_data(population_size=100000)
