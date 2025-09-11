-- ===========================================
-- 04_cleaning.sql
-- Auteur : Kahina ABBAD
-- Projet : Terre, Vent, Feu, Eau, Data
-- Objet  : Nettoyage et normalisation des données
--          issues des tables de staging (incendies
--          et communes), pour alimenter les tables
--          "propres" utilisables dans les jointures.
-- ===========================================

-- ===========================================
-- 1) Normalisation du code INSEE
-- ===========================================
-- Le code INSEE peut être écrit de différentes façons
-- selon les sources. On applique ici :
--  - trim() pour supprimer les espaces
--  - replace() pour nettoyer
--  - upper() pour forcer en majuscule
--  - substr(...,-5) pour garder 5 caractères (ex: "01345")
-- Résultat : un champ standardisé "code_insee_norm"
-- utilisable dans les jointures.
UPDATE communes_stage
SET code_insee_norm = 
    substr('00000' || upper(replace(trim(COALESCE(code_insee, insee)), ' ', '')), -5);

UPDATE incendies_stage
SET code_insee_norm = 
    substr('00000' || upper(replace(trim(code_insee), ' ', '')), -5);

-- ===========================================
-- 2) Suppression des éventuelles lignes d'en-tête
-- ===========================================
-- Lors de l'import CSV, il arrive que la première ligne
-- (les noms de colonnes) soit insérée comme une donnée.
-- On les supprime par heuristique :
--  - si lat/lon = "lat"/"lon"
--  - si annee/mois/jour contiennent les mots-clés
DELETE FROM communes_stage
WHERE lower(lat) = 'lat' OR lower(lon) = 'lon';

DELETE FROM incendies_stage
WHERE lower(annee) = 'annee' OR lower(mois) = 'mois'
   OR lower(jour) = 'jour' OR lower(code_insee) = 'code_insee';

-- ===========================================
-- 3) Alimentation des tables CLEAN
-- ===========================================

-- COMMUNES : on garde les champs utiles
DELETE FROM communes_clean;
INSERT INTO communes_clean
SELECT 
  code_insee,
  insee,
  nom,
  lat,
  lon,
  code_insee_norm
FROM communes_stage
WHERE code_insee_norm IS NOT NULL AND code_insee_norm <> '';

-- INCENDIES : on convertit certaines colonnes en nombres
--   - annee/mois/jour en INTEGER
--   - surface_brulee en REAL (on remplace virgule par point)
DELETE FROM incendies_clean;
INSERT INTO incendies_clean
SELECT 
  id,
  date,
  CAST(annee AS INTEGER) AS annee,
  CAST(mois AS INTEGER)  AS mois,
  CAST(jour AS INTEGER)  AS jour,
  heure,
  code_insee,
  code_insee_norm,
  commune,
  departement,
  region,
  cause,
  type_vegetation,
  CASE 
    WHEN surface_brulee IS NULL OR trim(surface_brulee) = '' THEN NULL
    ELSE CAST(replace(surface_brulee, ',', '.') AS REAL)
  END AS surface_brulee
FROM incendies_stage;

-- ===========================================
-- 4) Index pour optimiser les jointures
-- ===========================================
-- On ajoute des index sur code_insee_norm pour
-- accélérer les futures jointures et requêtes.
CREATE INDEX IF NOT EXISTS idx_inc_clean_insee ON incendies_clean(code_insee_norm);
CREATE INDEX IF NOT EXISTS idx_com_clean_insee ON communes_clean(code_insee_norm);
