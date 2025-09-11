-- 03_load_communes.sql

.mode csv
.separator ,

.import data/csvs/communes/communes.csv communes_stage
