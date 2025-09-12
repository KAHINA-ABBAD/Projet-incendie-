-- ===========================================
-- 04_build_join.sql
-- Auteur   : Kahina ABBAD
-- Projet   : Terre, Vent, Feu, Eau, Data
-- Objectif : Construire la table enrichie
--            incendies_communes avec la jointure
-- ===========================================

-- Supprimer la table si elle existe déjà
DROP TABLE IF EXISTS incendies_communes;

-- Créer la table enrichie avec jointure
CREATE TABLE incendies_communes AS
SELECT
  i."Année"         AS annee,
  i."Numéro"        AS numero,
  i."Département"   AS departement,
  i."Code INSEE"    AS code_insee,
  i."Nom de la commune" AS commune_incendie,
  i."Date de première alerte" AS date_alerte,
  i."Surface parcourue (m2)" AS surface_parcourue_m2,
  i."Type de peuplement" AS type_peuplement,
  i."Nature"        AS nature,
  i."Nombre de décès" AS nb_deces,
  i."Nombre de bâtiments totalement détruits" AS nb_batiments_totalement_detruits,
  i."Nombre de bâtiments partiellement détruits" AS nb_batiments_partiellement_detruits,
  c.nom_standard    AS commune_ref,
  c.latitude_centre AS lat,
  c.longitude_centre AS lon,
  c.population,
  c.superficie_km2,
  c.densite
FROM incendies i
LEFT JOIN communes c
  ON i.code_insee_norm = c.code_insee_norm;

