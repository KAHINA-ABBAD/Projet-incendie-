-- ===========================================
-- 03_load_communes.sql
-- Auteur : Kahina ABBAD
-- Projet : Terre, Vent, Feu, Eau, Data
-- Objet  : Importation du fichier CSV des communes
--          (référentiel géographique INSEE) dans
--          la table de staging "communes_stage".
-- ===========================================

-- ===========================================
-- Paramétrage du mode d'import pour SQLite
-- ===========================================

-- Indique que les fichiers à importer sont au format CSV
.mode csv

-- Définit le séparateur utilisé dans le fichier communes (virgule)
.separator ,

-- ===========================================
-- Importation du référentiel des communes
-- ===========================================
-- On importe le fichier CSV "communes.csv"
-- situé dans data/csvs/communes/ vers la table
-- de staging "communes_stage".
--
-- ⚠️ Vérifie que ton fichier contient bien au minimum :
--   - un code INSEE (ex: code_insee ou insee)
--   - un nom de commune
--   - une latitude (lat / latitude)
--   - une longitude (lon / longitude)
--
-- Ces colonnes seront ensuite normalisées dans
-- le script 04_cleaning.sql
-- ===========================================

.import data/csvs/communes/communes.csv communes_stage

-- ===========================================
-- Vérification rapide (à lancer dans sqlite3)
-- ===========================================
-- .tables
-- SELECT COUNT(*) FROM communes_stage;
-- SELECT * FROM communes_stage LIMIT 5;
