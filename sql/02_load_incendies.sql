-- 02_load_incendies.sql

.mode csv
.separator ;

-- IMPORTANT : on va importer chaque fichier dans la même table de staging
-- Remplace <LISTE_DE_FICHIERS> par tes 10 fichiers .csv
-- Tu peux aussi lancer .import à la main pour chaque fichier.

-- Exemples (duplique/édite une ligne par fichier) :
.import data/csvs/incendies/Incendies_1.csv incendies_stage
.import data/csvs/incendies/Incendies_2.csv incendies_stage
.import data/csvs/incendies/Incendies_3.csv incendies_stage
.import data/csvs/incendies/Incendies_4.csv incendies_stage
.import data/csvs/incendies/Incendies_5.csv incendies_stage
.import data/csvs/incendies/Incendies_6.csv incendies_stage
.import data/csvs/incendies/Incendies_7.csv incendies_stage
.import data/csvs/incendies/Incendies_8.csv incendies_stage
.import data/csvs/incendies/Incendies_9.csv incendies_stage
.import data/csvs/incendies/Incendies_10.csv incendies_stage
