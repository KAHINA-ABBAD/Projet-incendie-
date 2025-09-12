-- ===========================================
-- 05_quality_checks.sql (version parlante)
-- Auteur   : Kahina ABBAD
-- Projet   : Terre, Vent, Feu, Eau, Data
-- Objectif : Contrôles qualité + affichages lisibles
-- ===========================================

-- ================================
-- 1) Volumétrie des tables
-- ================================
SELECT '==> Nombre de lignes dans incendies' AS check_name, COUNT(*) AS valeur FROM incendies
UNION ALL
SELECT '==> Nombre de lignes dans communes', COUNT(*) FROM communes
UNION ALL
SELECT '==> Nombre de lignes dans incendies_communes', COUNT(*) FROM incendies_communes;

-- ================================
-- 2) % sans coordonnées
-- ================================
SELECT 
  '==> % d''incendies sans coordonnées' AS check_name,
  ROUND(100.0 * SUM(CASE WHEN lat IS NULL OR lon IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) 
  || '%' AS valeur
FROM incendies_communes;

-- ================================
-- 3) Répartition des incendies par années
-- ================================
-- SELECT '==> Année ' || annee AS check_name,
--        COUNT(*) || ' incendies' AS valeur
-- FROM incendies_communes
-- GROUP BY annee
-- ORDER BY annee;

-- ================================
-- 4) Top 10 causes
-- ================================
SELECT '==> Cause : ' || COALESCE(nature,'(non renseignée)') AS check_name,
       COUNT(*) || ' cas' AS valeur
FROM incendies_communes
GROUP BY nature
ORDER BY COUNT(*) DESC
LIMIT 10;

-- ================================
-- 5) Valeurs suspectes (surface négative)
-- ================================
SELECT '==> Surfaces négatives détectées ?' AS check_name,
       CASE 
         WHEN COUNT(*) = 0 THEN '==> Aucune anomalie'
         ELSE '==> ' || COUNT(*) || ' valeurs négatives'
       END AS valeur
FROM incendies_communes
WHERE surface_parcourue_m2 < 0;
