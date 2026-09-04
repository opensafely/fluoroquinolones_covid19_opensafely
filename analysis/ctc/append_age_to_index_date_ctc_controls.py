from ehrql import codelist_from_csv, create_dataset, table_from_file, years, months, weeks, days, show
from ehrql.tables.tpp import patients, clinical_events, medications
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
neuropathy_newdx_codes = codelist_from_csv("codelists/user-jacklsbrist-peripheral-neuropathy.csv", column = "code")

combo_outcome_codes = tendinitis_codes + neuropathy_newdx_codes

#Here we take the potential controls, to which we have appended a random index date and we calculate their age
#on the index date to allow us to use age and index date for matching

CONTROLS = "output/ctc_data_ptnl_controls_indexappended.csv.gz"

indexed_controls = table_from_file(
    CONTROLS,
    columns={
        "sex":str,
        "index_date":datetime.date
    }
)

dataset = create_dataset()
dataset.define_population(indexed_controls.exists_for_patient())

dataset.index_date = indexed_controls.index_date

dataset.age = patients.age_on(indexed_controls.index_date)
dataset.sex = indexed_controls.sex

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


