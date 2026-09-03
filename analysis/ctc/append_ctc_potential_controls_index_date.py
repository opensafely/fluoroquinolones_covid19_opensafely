import csv
import gzip
import random
from datetime import date, timedelta

# Define start and end
start_date = date(2010, 12, 1)
end_date = date(2024, 8, 1)

# Read in potential controls
with gzip.open("output/ctc_data_potential_controls_tendinitis.csv.gz", "rt") as f:
    reader = csv.DictReader(f)
    data = list(reader)

# Generate a random index date
days = (end_date - start_date).days

for row in data:
    random_days = random.randint(0, days)
    row['index_date'] = start_date + timedelta(days=random_days)

# Save the updated data
with gzip.open(
    "output/ctc_data_ptnl_controls_indexappended.csv.gz",
    "wt",
    newline=""
) as f:
    writer = csv.DictWriter(f, fieldnames=data[0].keys())
    writer.writeheader()
    writer.writerows(data)