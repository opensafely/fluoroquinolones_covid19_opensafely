from ehrql import codelist_from_csv, create_dataset, table_from_file, years, months, weeks, days, show
from ehrql.tables.tpp import patients, clinical_events, medications, practice_registrations
import datetime

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

#Here we take the potential controls, to which we have appended a random index date and we calculate their age
#on the index date to allow us to use age and index date for matching

CONTROLS = "output/ctc_data_potential_controls_tendinitis_indexappended.csv.gz"

indexed_controls = table_from_file(
    CONTROLS,
    columns={
        "sex":str,
        "index_date":datetime.date
    }
)

dataset = create_dataset()


#Need to define registration 1y before index date - as was done for cases

has_registration_1y_before_index =  (
    practice_registrations.where(practice_registrations.start_date <= (indexed_controls.index_date - years(1)))
    .exists_for_patient()
)

dataset.define_population(indexed_controls.exists_for_patient() &
                          has_registration_1y_before_index)

dataset.configure_dummy_data(population_size=100000)

dataset.index_date = indexed_controls.index_date


dataset.age = patients.age_on(indexed_controls.index_date)
dataset.sex = indexed_controls.sex

dataset.has_patient_record = patients.exists_for_patient()
dataset.date_of_birth = patients.date_of_birth
dataset.index_date_is_missing = indexed_controls.index_date.is_null()
dataset.patient_table_sex = patients.sex

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
                                        indexed_controls.index_date - start_offset,
                                        indexed_controls.index_date - end_offset
                )
            )
            .exists_for_patient()
        )


