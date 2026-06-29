######################################

# This script provides the formal specification of the study data that will be extracted from
# the OpenSAFELY database.

#Jack Stanley

#opensafely exec ehrql:v1 generate-dataset analysis/dataset_definition.py

#Make dummy data using opensafely exec ehrql:v1 create-dummy-tables dataset_definition.py dummy_tables
#Run dataset definition on dummy data already generated - opensafely exec ehrql:v1 generate-dataset dataset_definition.py --dummy-tables dummy_tables

######################################

#COuld this be one dataset and then another one for CTC?

from ehrql import create_dataset, codelist_from_csv, years, months, weeks, days, show, case, when
from ehrql.tables.tpp import patients, medications, practice_registrations, addresses, clinical_events, apcs, ons_deaths
from codelists import *

#To do - get bmi to work

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

all_abx_codes = amoxicillin_codes + amox_clavulanicacid_codes + cefalexin_codes + trimethoprim_codes + trim_sulfa_codes +fluoroquinolone_codes

cohort_abx_codes = amox_clavulanicacid_codes + fluoroquinolone_codes

#Outcome codes

tendinitis_codes = codelist_from_csv("codelists/user-jacklsbrist-tendinitis.csv", column = "code")
neuropathy_newdx_codes = codelist_from_csv("codelists/user-jacklsbrist-peripheral-neuropathy.csv", column = "code")

combo_outcome_codes = tendinitis_codes + neuropathy_newdx_codes

#Covariate/demographic codes

ethnicity_codelist_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="snomedcode",
    category_column="Grouping_16",
)

ethnicity_codelist_6 = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv", 
    column="snomedcode", 
    category_column = "Grouping_6"
    )
clear_smoking_codes = codelist_from_csv("codelists/opensafely-smoking-clear.csv", column = "CTV3Code", category_column = "Category")
bmi_codelist = codelist_from_csv("codelists/primis-covid19-vacc-uptake-bmi.csv", column = "code")
harmful_alcohol_codelist = codelist_from_csv("codelists/opensafely-hazardous-alcohol-drinking.csv", column = "code")


#Comorbidity codes

        #ctv3
diabetes_codelist = codelist_from_csv("codelists/opensafely-diabetes.csv", column = "CTV3ID")
dementia_codelist = codelist_from_csv("codelists/opensafely-dementia-complete.csv", column = "code")
hiv_codelist = codelist_from_csv("codelists/opensafely-heart-failure.csv", column = "CTV3ID")
heart_failure_codelist = codelist_from_csv("codelists/opensafely-hiv.csv", column = "CTV3ID")
chronic_liver_disease_codelist = codelist_from_csv("codelists/opensafely-chronic-liver-disease.csv", column = "CTV3ID")
multiple_sclerosis_codelist = codelist_from_csv("codelists/opensafely-multiple-sclerosis.csv", column = "CTV3ID")
rheumatoid_arthritis_codelist = codelist_from_csv("codelists/opensafely-rheumatoid-arthritis.csv", column = "CTV3ID")
solid_organ_transplant_codelist = codelist_from_csv("codelists/opensafely-solid-organ-transplantation.csv", column = "CTV3ID")
lung_cancer_codelist = codelist_from_csv("codelists/opensafely-lung-cancer.csv", column = "CTV3ID")
notlung_nothaem_cancer_codelist = codelist_from_csv("codelists/opensafely-cancer-excluding-lung-and-haematological.csv", column = "CTV3ID")
haem_cancer_codelist = codelist_from_csv("codelists/opensafely-haematological-cancer.csv", column = "CTV3ID")
stroke_codelist = codelist_from_csv("codelists/opensafely-incident-non-traumatic-stroke.csv", column = "CTV3ID")
tia_codelist = codelist_from_csv("codelists/opensafely-transient-ischaemic-attack.csv", column = "code")
chronic_resp_exc_asthma_codelist = codelist_from_csv("codelists/opensafely-chronic-respiratory-disease.csv", column = "CTV3ID")
asthma_codelist = codelist_from_csv("codelists/opensafely-asthma-diagnosis.csv", column = "CTV3ID")
hemiplegia_codelist = codelist_from_csv("codelists/user-jacklsbrist-hemiplegia.csv", column = "code")

all_cancer_codelist = lung_cancer_codelist + notlung_nothaem_cancer_codelist + haem_cancer_codelist
stroke_tia_codelist = stroke_codelist + tia_codelist
chronic_resp_codelist = chronic_resp_exc_asthma_codelist + asthma_codelist

        #ctv3 dictionary
comorbidity_codelists_ctv3 = {
    "had_cancer":all_cancer_codelist,
    "chronic_liver_disease":chronic_liver_disease_codelist,
    "chronic_resp_disease":chronic_resp_codelist,
    "diabetes":diabetes_codelist,
    "dementia":dementia_codelist,
    "hiv":hiv_codelist,
    "heart_failure":heart_failure_codelist,
    "hemiplegia":hemiplegia_codelist,
    "multiple_sclerosis":multiple_sclerosis_codelist,
    "rheumatoid_arthritis":rheumatoid_arthritis_codelist,
    "solid_organ_transplant":solid_organ_transplant_codelist,
    "stroke_tia":stroke_tia_codelist
}

        #snomed
coronary_hd_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-chd_cod.csv", column = "code")
hypertension_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-hyp_cod.csv", column = "code")
ckd_codelist =codelist_from_csv("codelists/primis-covid19-vacc-uptake-old-ckd15_cod.csv", column = "code")
pvd_codelist = codelist_from_csv("codelists/qcovid-has_peripheral_vascular_disease.csv", column = "code")
aaa_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-aaa_cod.csv", column = "code")
peptic_ulcer_codelist = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-peptic-ulceration-codes.csv", column = "code")

        #snomed dictionary
comorbidity_codelists_snomedct = {
    "aaa":aaa_codelist,
    "ckd":ckd_codelist,
    "coronary_hd":coronary_hd_codelist,
    "hypertension":hypertension_codelist,
    "peptic_ulcer":peptic_ulcer_codelist,
    "pvd":pvd_codelist
}

#Non-abx prescription codes
        #Need more when available

corticosteroid_codes = codelist_from_csv("codelists/qcovid-is_prescribed_oral_steroids.csv", column = "code")

phenytoin_codes = codelist_from_csv("codelists/user-jacklsbrist-phenytoin-dmd.csv", column = "code")
amiodarone_codes = codelist_from_csv("codelists/pincer-amio.csv", column = "code")
metronidazole_codes = codelist_from_csv("codelists/ukhsa-metronidazole-tinidazole-and-ornidazole-antibacterials.csv", column = "code")
nitrofurantoin_codes = codelist_from_csv("codelists/user-jacklsbrist-nitrofurantoin-dmd.csv", column = "code")

drug_causes_of_neuropathy_codes = phenytoin_codes  + amiodarone_codes + metronidazole_codes + nitrofurantoin_codes

#Allergy codes

fluoroquinolone_allergy_codes = codelist_from_csv("codelists/user-jacklsbrist-allergy-to-fluoroquinolones.csv", column = "code")
co_amox_allergy_codes = codelist_from_csv("codelists/user-jacklsbrist-allergy-to-co-amoxiclav.csv", column = "code")

cohort_abx_allergy_codes = fluoroquinolone_allergy_codes + co_amox_allergy_codes

#This is date of first prescription of study abx for cohort

first_cohort_rx = medications.where(
    medications.dmd_code.is_in(cohort_abx_codes)
).where(
    medications.date.is_on_or_between(start_date, end_date)
).sort_by(
    medications.date
).first_for_patient() #set for use in rest of dataset definition

first_cohort_abx_rx = first_cohort_rx.date

dataset.fluoroquinolone_exp = first_cohort_rx.dmd_code.is_in(fluoroquinolone_codes)

has_registration_1y_before_cohort_abx =  (
    practice_registrations.where(practice_registrations.start_date <= (first_cohort_abx_rx + years(1)))
    .except_where(practice_registrations.end_date < end_date)
    .exists_for_patient()
)

# dataset.fluoroquinolone_exp = medications.where(
#     medications.dmd_code.is_in(cohort_abx_codes)).where(
#          medications.date.is_on_or_between(start_date, end_date) - to check if still needed
#          ).sort_by(
#         medications.date
# ).first_for_patient().where(medications.dmd_code.is_in(fluoroquinolone_codes)).exists_for_patient()



#Exclusion criteria

prior_tendinitis_or_neuropathy = clinical_events.where(
        clinical_events.snomedct_code.is_in(combo_outcome_codes) #Exclude those with pre-existing diagnosis of tendinitis
).where(
        clinical_events.date.is_on_or_before(first_cohort_abx_rx)
).exists_for_patient()

cohort_abx_allergy = clinical_events.where(
    clinical_events.snomedct_code.is_in(cohort_abx_allergy_codes)
).where(
    clinical_events.date.is_on_or_before(first_cohort_abx_rx) #Exclude allergies coded prior to receipt of drug
).exists_for_patient()

#Cohort definition

dataset.define_population(
     (patients.exists_for_patient()) &
     (has_registration_1y_before_cohort_abx) &
    ~(cohort_abx_allergy) &
    ~(prior_tendinitis_or_neuropathy) 
    )

dataset.configure_dummy_data(population_size=10000, timeout = 120)

        #Medication options - no longer needed - just use cohort first abx rx

# #This extracts first date of FQ prescription
# first_fluoroquinolone_date = medications.where(
#         medications.dmd_code.is_in(fluoroquinolone_codes)
# ).where(
#         medications.date.is_on_or_after(first_cohort_abx_rx)
# ).sort_by(
#         medications.date
# ).first_for_patient().date

# first_co_amox_date = medications.where(
#         medications.dmd_code.is_in(amox_clavulanicacid_codes)
# ).where(
#         medications.date.is_on_or_after(first_cohort_abx_rx)
# ).sort_by(
#         medications.date
# ).first_for_patient().date

# dataset.first_fluoroquinolone_date = first_fluoroquinolone_date
# dataset.first_co_amox_date = first_co_amox_date

        #Exposed or not - all 0s therefore should be coamox. But for sanity to check by coding coamox and comparing once generated

# dataset.fluoroquinolone_exp = (
#     first_fluoroquinolone_date.is_not_null()
# )

# dataset.coamox_exp = (
#     first_co_amox_date.is_not_null()
# )

#Outcome options - ICD-10 or SNOMED - any benefit to either cf the other? - Leave coded as start_date for now to check for santiy. 
# We should not be getting any coming up before the date of prescription of either

dataset.first_tendinitis_diagnosis_date = clinical_events.where(
        clinical_events.snomedct_code.is_in(tendinitis_codes)
).where(
        clinical_events.date.is_on_or_after(start_date)
).sort_by(
        clinical_events.date
).first_for_patient().date

dataset.first_neuropathy_diagnosis_date = clinical_events.where(
        clinical_events.snomedct_code.is_in(neuropathy_newdx_codes)
).where(
        clinical_events.date.is_on_or_after(start_date)
).sort_by(
        clinical_events.date
).first_for_patient().date


        #Demographics
dataset.sex = patients.sex
dataset.age = patients.age_on(first_cohort_abx_rx)
dataset.date_of_birth = patients.date_of_birth #Likely to need to calculate age at time of prescription later on
dataset.imd = addresses.for_patient_on(first_cohort_abx_rx).imd_rounded
patient_address = addresses.for_patient_on(first_cohort_abx_rx)
dataset.imd_decile = patient_address.imd_decile
dataset.date_of_death = ons_deaths.date

#BMI - is this best way to get bmi?
dataset.last_bmi = (
    clinical_events.where(
        clinical_events.snomedct_code.is_in(bmi_codelist))
        .sort_by(clinical_events.date)
        .last_for_patient()
        .numeric_value
)


#FOllowing work elsewhere on using this codelist and ethnicity 6 and 16. Lots of nas with dummy data. TBC if the same with real data

# Ethnicity 6 categories
ethnicity6 = clinical_events.where(
        clinical_events.snomedct_code.is_in(ethnicity_codelist_6)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).last_for_patient().snomedct_code.to_category(ethnicity_codelist_6)

dataset.ethnicity6 = case(
    when(ethnicity6 == "1").then("White"),
    when(ethnicity6 == "2").then("Mixed"),
    when(ethnicity6 == "3").then("South Asian"),
    when(ethnicity6 == "4").then("Black"),
    when(ethnicity6 == "5").then("Other"),
    when(ethnicity6 == "6").then("Not stated"),
    otherwise="Unknown"
)

# Ethnicity 16 categories
ethnicity16 = clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_codelist_16)
    ).where(
        clinical_events.date.is_on_or_before(end_date)
    ).sort_by(
        clinical_events.date
    ).last_for_patient().snomedct_code.to_category(ethnicity_codelist_16)

dataset.ethnicity16 = case(
    when(ethnicity16 == "1").then("White - British"),
    when(ethnicity16 == "2").then("White - Irish"),
    when(ethnicity16 == "3").then("White - Other"),
    when(ethnicity16 == "4").then("Mixed - White/Black Caribbean"),
    when(ethnicity16 == "5").then("Mixed - White/Black African"),
    when(ethnicity16 == "6").then("Mixed - White/Asian"),
    when(ethnicity16 == "7").then("Mixed - Other"),
    when(ethnicity16 == "8").then("Asian or Asian British - Indian"),
    when(ethnicity16 == "9").then("Asian or Asian British - Pakistani"),
    when(ethnicity16 == "10").then("Asian or Asian British - Bangladeshi"),
    when(ethnicity16 == "11").then("Asian or Asian British - Other"),
    when(ethnicity16 == "12").then("Black - Caribbean"),    
    when(ethnicity16 == "13").then("Black - African"),
    when(ethnicity16 == "14").then("Black - Other"),
    when(ethnicity16 == "15").then("Other - Chinese"),
    when(ethnicity16 == "16").then("Other - Other"),
    otherwise="Unknown"
)

#Smoking - include prior to first cohort abx prescription and then 7 days after to allow for coding at time of illness
###############################################################################
# from https://github.com/opensafely/early-inflammatory-arthritis/blob/069e61712fcc9a0c2ec2804ff36a9b773073291c/analysis/dataset_definition.py#L136
###############################################################################
  
most_recent_smoking_code = (
  (clinical_events.where(clinical_events.ctv3_code
  .is_in(clear_smoking_codes))
  .where(
        clinical_events.date.is_on_or_before(first_cohort_abx_rx + days(7)))
  .sort_by(clinical_events.date).last_for_patient()
  .ctv3_code.to_category(clear_smoking_codes))
)

def filter_codes_by_category(codelist, include):
    return {k:v for k,v in codelist.items() if v in include}

ever_smoked = (
  clinical_events.where(clinical_events.ctv3_code
  .is_in(filter_codes_by_category(clear_smoking_codes, include = ["S", "E"])))
  .exists_for_patient()
)

dataset.smoking_status = (case(
  when(most_recent_smoking_code == "S").then("Current"),
  when((most_recent_smoking_code == "E") 
  | ((most_recent_smoking_code == "N") 
  & (ever_smoked == True))).then("Former"),
  when((most_recent_smoking_code == "N") 
  & (ever_smoked == False)).then("Never"),
  otherwise = None)
)

#Alcohol -Think this is best option - just find those with ever harmful alcohol use

dataset.harmful_alcohol =(
    clinical_events.where(clinical_events.ctv3_code.is_in(harmful_alcohol_codelist))
    .where(clinical_events.date.is_on_or_before(first_cohort_abx_rx))
    .exists_for_patient()
) 


        #Frailty indicators

#n hosp appt last 6 months - these will need to be dynamically set based on when the individual is entered into the study.
#Cohort this = date of first prescription of either FQ or comparator. SCCS this is date of first tendinitis/peripheral neuropathy

dataset.n_hosp_appt_6m = apcs.where(apcs.admission_date.is_on_or_between(
    (first_cohort_abx_rx - months(6)), (first_cohort_abx_rx - days(1)) 
)).count_for_patient()


#n GP appt last 6 months 
        #Nb to d/w Will/Rose as per here - https://docs.opensafely.org/ehrql/reference/schemas/tpp/#appointments - leave with Rose 1/7

        #Comorbidities
#?need codelists - ctv3. Or snomed. Or both?
#TO put start date as date of rx for cohort (and event for CTC). Loop over these - need to do separately depending on whether using ctv3 or other

for condition, codelist in comorbidity_codelists_ctv3.items():
    setattr(
        dataset,
        f"has_{condition}",
        clinical_events.where(
            clinical_events.ctv3_code.is_in(codelist)
        ).where(
            clinical_events.date.is_before(first_cohort_abx_rx)
        ).exists_for_patient()
    )

for condition, codelist in comorbidity_codelists_snomedct.items():
    setattr(
        dataset,
        f"has_{condition}",
        clinical_events.where(
            clinical_events.snomedct_code.is_in(codelist)
        ).where(
            clinical_events.date.is_before(first_cohort_abx_rx)
        ).exists_for_patient()
    )

        #Indication for antibiotic treatment

        #Time
##Year exposure (cohort) or event (SCCS)
dataset.date_cohort_prescription = first_cohort_abx_rx
dataset.year_cohort_prescription = first_cohort_abx_rx.year


        #Specific covariates -

#Corticosteroid last 60d
#Nitrofurantoin, phenytoin, metronidazole, amiodarone last 60d

dataset.corticosteroid_60d_before_abx = medications.where(
    medications.dmd_code.is_in(corticosteroid_codes)
).where(
    medications.date.is_on_or_between(
        (first_cohort_abx_rx - days(60)), 
        (first_cohort_abx_rx - days(1))
)
).exists_for_patient()

dataset.drug_linked_to_neuropathy_60d_before_abx = medications.where(
    medications.dmd_code.is_in(drug_causes_of_neuropathy_codes)
).where(
    medications.date.is_on_or_between(
        (first_cohort_abx_rx - days(60)), 
        (first_cohort_abx_rx - days(1))
)
).exists_for_patient()

#Indication for treatment would be good
