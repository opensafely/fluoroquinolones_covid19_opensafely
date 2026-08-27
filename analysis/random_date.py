from ehrql import codelist_from_csv, create_dataset, table_from_file, years, months, weeks, days, show
from ehrql.tables.tpp import patients, clinical_events
from codelists import *

import datetime

from ehrql import table_from_file

import numpy as np
import random
from datetime import datetime, timedelta


CONTROLS = "output/ctc_data_potential_controls_tendinitis.csv.gz"

indexed_controls = table_from_file(
    CONTROLS,
    columns={
        "sex":str
    }
)

index_date = "2018-01-01"

dataset = create_dataset()
dataset.define_population(indexed_controls.exists_for_patient())

dataset.age = patients.age_on(index_date) 

show(dataset)
