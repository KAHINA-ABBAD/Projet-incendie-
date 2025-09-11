-- ===========================================
-- 05_join.sql
-- Auteur : Kahina ABBAD
-- Projet : Terre, Vent, Feu, Eau, Data
-- Objet  : Jointure entre les tables clean des
--          incendies et des communes pour créer
--          la table enrichie "incendies_enrichi".
-- ===========================================

-- ===========================================
-- 1) Reset de la table enrichie
-- ===========================================
-- On supprime le contenu précédent pour recharger
-- avec les données actualisées.
DELETE FROM incendies_enrichi;

-- ===========================================
-- 2) Alimentation de la table enrichie
-- ===========================================
-- On réalise une jointure entre :
--   - incendies_clean (incendies nettoyés)
--   - communes_clean  (communes nettoyées)
--
-- La jointure se fait sur "code_insee_norm".
-- L'objectif est d'ajouter aux incendies les
-- coordonnées géographiques (lat/lon) de leur
-- commune associée.
-- ===========================================
INSERT INTO incendies_enrichi (
  id, date, annee, mois, jour, heure,
  code_insee, code_insee_norm, commune, departement, region,
  cause, type_vegetation, surface_brulee, lat, lon
)
SELECT 
    i.id,
    i.date,
    i.annee,
    i.mois,
    i.jour,
    i.heure,
    i.code_insee,
    i.code_insee_norm,
    i.commune,
    i.departement,
    i.region,
    i.cause,
    i.type_vegetation,
    i.surface_brulee,
    CAST(replace(c.lat, ',', '.') AS REAL) AS lat,
    CAST(replace(c.lon, ',', '.') AS REAL) AS lon
FROM incendies_clean i
LEFT JOIN communes_clean c
  ON i.code_insee_norm = c.code_insee_norm;

-- ===========================================
-- 3) Index final
-- ===========================================
-- Création d'un index sur code_insee_norm pour
-- accélérer les requêtes et analyses futures.
CREATE INDEX IF NOT EXISTS idx_inc_enrichi_commune 
ON incendies_enrichi(code_insee_norm);
