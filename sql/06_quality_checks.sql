-- ===========================================
-- 06_quality_checks.sql
-- Auteur : Kahina ABBAD
-- Projet : Terre, Vent, Feu, Eau, Data
-- Objet  : Contrôles qualité et sanity checks
--          sur la base consolidée SQLite.
-- ===========================================

-- ===========================================
-- 1) Volumétrie par table (pipeline complet)
-- ===========================================
SELECT 'incendies_stage'  AS table, COUNT(*) AS n FROM incendies_stage
UNION ALL
SELECT 'communes_stage',        COUNT(*)     FROM communes_stage
UNION ALL
SELECT 'incendies_clean',       COUNT(*)     FROM incendies_clean
UNION ALL
SELECT 'communes_clean',        COUNT(*)     FROM communes_clean
UNION ALL
SELECT 'incendies_enrichi',     COUNT(*)     FROM incendies_enrichi;

-- Interprétation attendue :
-- - n(incendies_stage) > 0  : import CSV OK
-- - n(incendies_clean)  ≈ n(incendies_stage) (sauf lignes invalides)
-- - n(enrichi)           ≈ n(incendies_clean) (sauf si jointure perd des lignes)

-- ===========================================
-- 2) % de lignes sans coordonnées après jointure
--    (indique les codes INSEE non trouvés ou mal normalisés)
-- ===========================================
SELECT 
  ROUND(
    100.0 * SUM(CASE WHEN lat IS NULL OR lon IS NULL THEN 1 ELSE 0 END) 
    / NULLIF(COUNT(*),0), 
    2
  ) AS pct_sans_coord
FROM incendies_enrichi;

-- Si ce % est élevé :
-- - vérifier la normalisation code_insee_norm (04_cleaning.sql)
-- - vérifier les colonnes INSEE/lat/lon dans communes.csv
-- - vérifier la qualité des codes INSEE dans BDIFF

-- ===========================================
-- 3) Années disponibles (contrôle temporel)
-- ===========================================
SELECT annee, COUNT(*) AS n
FROM incendies_enrichi
GROUP BY annee
ORDER BY annee;

-- Attendu : progression cohérente des années, aucune année "NULL" ou aberrante.

-- ===========================================
-- 4) Top causes (profil des données)
-- ===========================================
SELECT cause, COUNT(*) AS n
FROM incendies_enrichi
GROUP BY cause
ORDER BY n DESC
LIMIT 10;

-- Vérifier que les valeurs de "cause" sont propres (pas de doublons orthographiques).

-- ===========================================
-- 5) Valeurs suspectes : surfaces négatives
-- ===========================================
SELECT COUNT(*) AS nb_surface_neg
FROM incendies_enrichi
WHERE surface_brulee < 0;

-- Devrait être 0. Si > 0 : corriger l’ETL/cleaning.

-- ===========================================
-- 6) (Optionnel) Lignes sans coordonnées : top communes
--    pour diagnostiquer les problèmes d’INSEE
-- ===========================================
-- Renvoie les communes les plus souvent sans lat/lon
SELECT 
  code_insee, commune, COUNT(*) AS n
FROM incendies_enrichi
WHERE lat IS NULL OR lon IS NULL
GROUP BY code_insee, commune
ORDER BY n DESC
LIMIT 15;

-- ===========================================
-- 7) (Optionnel) Répartition par département
-- ===========================================
SELECT departement, COUNT(*) AS n
FROM incendies_enrichi
GROUP BY departement
ORDER BY n DESC
LIMIT 20;

-- ===================================================
-- 8) (Optionnel) Duplicats potentiels d'identifiants
--    (si "id" est censé être unique)
-- ===================================================
SELECT id, COUNT(*) AS n
FROM incendies_enrichi
GROUP BY id
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 20;

-- ===========================================
-- 9) Intégrité SQLite (sanity check bas niveau)
-- ===========================================
PRAGMA integrity_check;

-- Retour attendu : "ok"
