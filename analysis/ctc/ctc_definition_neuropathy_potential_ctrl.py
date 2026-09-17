######################################

# This script provides the formal specification of the data that will be extracted from
# the OpenSAFELY database for the case-time-control analysis.

#Jack Stanley

#opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py

#nb check https://docs.opensafely.org/case-control-studies/#background

######################################

from ehrql import create_dataset, codelist_from_csv
from ehrql.tables.tpp import patients, clinical_events

dataset = create_dataset()

start_date = "2010-12-01" ##TBC
end_date = "2024-08-01"  ##TBC


# #Outcome codes

neuropathy_newdx_codes = codelist_from_csv("codelists/user-jacklsbrist-peripheral-neuropathy.csv", column = "code")


    #Registration 1y before start date - to be defined after index date generated

#Exclusion criteria - those with prior neuropathy

prior_neuropathy = clinical_events.where(
        clinical_events.snomedct_code.is_in(neuropathy_newdx_codes) #Exclude those with pre-existing diagnoses
).where(
        clinical_events.date.is_on_or_before(start_date)
).exists_for_patient()

#Exclusion criteria - drug allergy to those ?Is this necessary for the ctc?

#Dataset definition

dataset.define_population(
     (patients.exists_for_patient()) &
    ~(prior_neuropathy) 
    )

dataset.sex = patients.sex
dataset.configure_dummy_data(population_size=1000000)
