-- ===========================================
-- 02_load_incendies.sql
-- Auteur : Kahina ABBAD
-- Projet : Terre, Vent, Feu, Eau, Data
-- Objet  : Importation des fichiers CSV BDIFF
--          dans la table de staging "incendies_stage".
-- ===========================================

-- ===========================================
-- Paramétrage du mode d'import pour SQLite
-- ===========================================

-- Indique que les fichiers CSV doivent être lus en mode CSV
.mode csv

-- Définit le séparateur utilisé dans les fichiers BDIFF (;)
.separator ;

-- ===========================================
-- Importation des données
-- ===========================================
-- Chaque fichier CSV BDIFF est importé dans la
-- table de staging "incendies_stage".
-- On duplique la ligne .import pour chaque fichier.
--
-- ⚠️ Important :
-- - Adapter les noms de fichiers ci-dessous aux
--   vrais noms présents dans data/csvs/incendies/
-- - Conserver le chemin relatif
-- - Tous les fichiers sont fusionnés dans UNE
--   seule table "incendies_stage"
-- ===========================================

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

-- ===========================================
-- Vérification rapide (à lancer dans sqlite3)
-- ===========================================
-- .tables
-- SELECT COUNT(*) FROM incendies_stage;
-- SELECT * FROM incendies_stage LIMIT 5;
