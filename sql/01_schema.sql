-- ===========================================
-- 01_schema.sql
-- Auteur : Kahina ABBAD
-- Projet : Terre, Vent, Feu, Eau, Data
-- Objet  : Définition du schéma de base SQLite
--          pour l'intégration et la consolidation
--          des données BDIFF (incendies) et des
--          communes (référentiel géographique).
-- ===========================================

-- Active un mode d'écriture performant (WAL = Write Ahead Log)
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- ===========================================
-- 1) Table de STAGING : incendies_stage
--    Cette table reçoit les données brutes BDIFF
--    importées directement depuis les CSV.
--    Toutes les colonnes sont en TEXT pour éviter
--    les erreurs de typage au moment de l'import.
--    Le nettoyage et la conversion seront faits
--    ensuite dans la table "incendies_clean".
-- ===========================================
DROP TABLE IF EXISTS incendies_stage;
CREATE TABLE incendies_stage (
  id TEXT,                -- identifiant (concat Département + Numéro si besoin)
  date TEXT,              -- date brute de l'incendie
  annee TEXT,             -- année brute
  mois TEXT,              -- mois brut
  jour TEXT,              -- jour brut
  heure TEXT,             -- heure brute
  code_insee TEXT,        -- code INSEE de la commune
  commune TEXT,           -- nom de la commune
  departement TEXT,       -- département concerné
  region TEXT,            -- région (si disponible)
  cause TEXT,             -- cause du feu (naturelle, humaine…)
  type_vegetation TEXT,   -- type de végétation touchée
  surface_brulee TEXT,    -- surface brûlée (brut, texte)
  code_insee_norm TEXT    -- code INSEE normalisé (ajouté après import)
);

-- ===========================================
-- 2) Table de STAGING : communes_stage
--    Cette table reçoit les données brutes des
--    communes (référentiel géographique INSEE).
--    On garde tout en TEXT au départ.
-- ===========================================
DROP TABLE IF EXISTS communes_stage;
CREATE TABLE communes_stage (
  code_insee TEXT,        -- code INSEE tel que fourni
  insee TEXT,             -- alternative si une autre colonne existe
  nom TEXT,               -- nom de la commune
  lat TEXT,               -- latitude brute
  lon TEXT,               -- longitude brute
  code_insee_norm TEXT    -- code INSEE normalisé (zfill sur 5 chiffres)
);

-- ===========================================
-- 3) Tables CLEAN
--    Ces tables reçoivent les données nettoyées,
--    typées et prêtes pour les jointures.
--    On les construit à partir des tables de staging.
-- ===========================================
DROP TABLE IF EXISTS incendies_clean;
CREATE TABLE incendies_clean AS
SELECT * FROM incendies_stage WHERE 0;  -- copie de structure, sans données

DROP TABLE IF EXISTS communes_clean;
CREATE TABLE communes_clean AS
SELECT * FROM communes_stage WHERE 0;

-- ===========================================
-- 4) Table ENRICHIE : incendies_enrichi
--    Table finale obtenue après la jointure entre
--    incendies_clean et communes_clean.
--    Elle contient les colonnes principales +
--    la latitude/longitude de la commune.
-- ===========================================
DROP TABLE IF EXISTS incendies_enrichi;
CREATE TABLE incendies_enrichi (
  id TEXT,                -- identifiant unique de l'incendie
  date TEXT,              -- date brute
  annee INTEGER,          -- année numérique
  mois INTEGER,           -- mois numérique
  jour INTEGER,           -- jour numérique
  heure TEXT,             -- heure (si dispo)
  code_insee TEXT,        -- code INSEE brut
  code_insee_norm TEXT,   -- code INSEE normalisé
  commune TEXT,           -- nom de la commune
  departement TEXT,       -- département
  region TEXT,            -- région (facultatif)
  cause TEXT,             -- cause de l'incendie
  type_vegetation TEXT,   -- type de végétation
  surface_brulee REAL,    -- surface brûlée convertie en numérique
  lat REAL,               -- latitude de la commune
  lon REAL                -- longitude de la commune
);

-- ===========================================
-- 5) Index
--    Les index accélèrent les jointures et recherches
--    sur les codes INSEE, très utilisés dans ce projet.
-- ===========================================
CREATE INDEX IF NOT EXISTS idx_inc_stage_insee_norm ON incendies_stage(code_insee_norm);
CREATE INDEX IF NOT EXISTS idx_com_stage_insee_norm ON communes_stage(code_insee_norm);
CREATE INDEX IF NOT EXISTS idx_inc_enrichi_insee_norm ON incendies_enrichi(code_insee_norm);
