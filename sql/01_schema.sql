-- 01_schema.sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- 1) Table de staging pour BDIFF (toutes colonnes en TEXT → on nettoie ensuite)
DROP TABLE IF EXISTS incendies_stage;
CREATE TABLE incendies_stage (
  -- mets une liste large pour couvrir toutes les colonnes possibles de BDIFF
  -- si tu ne connais pas les noms exacts, garde TEXT générique puis on sélectionnera ce qui nous intéresse
  -- Exemple de colonnes usuelles (à adapter si besoin) :
  id TEXT,
  date TEXT,
  annee TEXT,
  mois TEXT,
  jour TEXT,
  heure TEXT,
  code_insee TEXT,
  commune TEXT,
  departement TEXT,
  region TEXT,
  cause TEXT,
  type_vegetation TEXT,
  surface_brulee TEXT,
  -- colonne normalisée ajoutée après import
  code_insee_norm TEXT
);

-- 2) Table de staging pour communes (référentiel)
DROP TABLE IF EXISTS communes_stage;
CREATE TABLE communes_stage (
  code_insee TEXT,
  insee TEXT,
  nom TEXT,
  lat TEXT,
  lon TEXT,
  -- normalisée
  code_insee_norm TEXT
);

-- 3) Tables “propres” (après nettoyage)
DROP TABLE IF EXISTS incendies_clean;
CREATE TABLE incendies_clean AS
SELECT * FROM incendies_stage WHERE 0;  -- copie de structure

DROP TABLE IF EXISTS communes_clean;
CREATE TABLE communes_clean AS
SELECT * FROM communes_stage WHERE 0;

-- 4) Table enrichie (jointure)
DROP TABLE IF EXISTS incendies_enrichi;
CREATE TABLE incendies_enrichi (
  id TEXT,
  date TEXT,
  annee INTEGER,
  mois INTEGER,
  jour INTEGER,
  heure TEXT,
  code_insee TEXT,
  code_insee_norm TEXT,
  commune TEXT,
  departement TEXT,
  region TEXT,
  cause TEXT,
  type_vegetation TEXT,
  surface_brulee REAL,
  lat REAL,
  lon REAL
);

-- Index utiles
CREATE INDEX IF NOT EXISTS idx_inc_stage_insee_norm ON incendies_stage(code_insee_norm);
CREATE INDEX IF NOT EXISTS idx_com_stage_insee_norm ON communes_stage(code_insee_norm);
CREATE INDEX IF NOT EXISTS idx_inc_enrichi_insee_norm ON incendies_enrichi(code_insee_norm);
