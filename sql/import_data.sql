-- ===========================================
-- 02_import_data.sql
-- Auteur   : Kahina ABBAD
-- Projet   : Terre, Vent, Feu, Eau, Data
-- Objectif : Importer les CSV dans SQLite
-- ===========================================

-- Définir le mode CSV et les séparateurs
-- Les incendies utilisent ";" comme séparateur
.mode csv
.separator ";"

-- ================================
-- Import des fichiers INCENDIES
-- ================================
.import data/csvs/incendies/incendie_1.csv incendies
.import data/csvs/incendies/incendie_2.csv incendies
.import data/csvs/incendies/incendie_3.csv incendies
.import data/csvs/incendies/incendie_4.csv incendies
.import data/csvs/incendies/incendie_5.csv incendies
.import data/csvs/incendies/incendie_6.csv incendies
.import data/csvs/incendies/incendie_7.csv incendies
.import data/csvs/incendies/incendie_8.csv incendies
.import data/csvs/incendies/incendie_9.csv incendies
.import data/csvs/incendies/incendie_10.csv incendies

-- ================================
-- Import du fichier COMMUNES
-- ================================
-- Les communes utilisent "," comme séparateur
.separator ","
.import data/csvs/communes/communes.csv communes
