-- ===========================================
-- Projet   : Terre, Vent, Feu, Eau, Data
-- Auteur   : Kahina ABBAD
-- Objectif : Créer les tables principales sous SQLite
-- ===========================================

-- Activer le mode WAL (Write Ahead Logging) pour de meilleures performances
-- et mettre la synchro en mode NORMAL (plus rapide qu'en FULL).
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- ================================
-- 1) Table INCENDIES
-- ================================
-- Contient les données des incendies issues des fichiers CSV BDIFF.
-- On choisit des types adaptés :
--   - INTEGER pour les entiers (année, numéro, décès…)
--   - REAL    pour les surfaces (valeurs numériques avec décimales)
--   - TEXT    pour les libellés (commune, nature, précision…)
--   - code_insee_norm est une colonne calculée plus tard
--     (normalisation des codes INSEE sur 5 caractères).
DROP TABLE IF EXISTS incendies;
CREATE TABLE incendies (
  annee INTEGER,                           -- Année de l’incendie (ex: 2020)
  numero INTEGER,                          -- Numéro unique de l’incendie
  departement TEXT,                        -- Département (code ou nom)
  code_insee TEXT,                         -- Code INSEE brut du CSV
  commune TEXT,                            -- Nom de la commune
  date_alerte TEXT,                        -- Date/heure de l’alerte (format ISO)
  surface_parcourue_m2 REAL,               -- Surface totale parcourue (m²)
  surface_foret_m2 REAL,                   
  surface_maquis_m2 REAL,                  
  surface_autres_naturelles_m2 REAL,       
  surface_agricoles_m2 REAL,               
  surface_autres_m2 REAL,                  
  surface_autres_terres_boisées_m2 REAL,   
  surface_non_boisées_naturelles_m2 REAL,  
  surface_non_boisées_artificialisées_m2 REAL,
  surface_non_boisées_m2 REAL,
  precision_surfaces TEXT,                 
  type_peuplement TEXT,                    -- Type de peuplement (forêt, maquis…)
  nature TEXT,                             -- Cause/nature de l’incendie
  degats TEXT,                             -- Infos sur décès/bâtiments
  nb_deces INTEGER,                        -- Nombre de décès
  nb_batiments_totalement_detruits INTEGER,
  nb_batiments_partiellement_detruits INTEGER,
  precision_donnee TEXT,                   -- Précision de la donnée
  code_insee_norm TEXT                     -- Code INSEE normalisé (à calculer)
);

-- ================================
-- 2) Table COMMUNES
-- ================================
-- Contient le référentiel des communes françaises avec beaucoup d’attributs.
-- On conserve toutes les colonnes utiles pour enrichir les incendies :
--   - Informations administratives (région, département, EPCI…)
--   - Données géographiques (lat/lon, altitude…)
--   - Données démographiques (population, densité…)
--   - Données descriptives (gentilé, Wikipédia…)
--   - code_insee_norm = normalisation pour la jointure
DROP TABLE IF EXISTS communes;
CREATE TABLE communes (
  code_insee TEXT,
  insee TEXT,
  nom_standard TEXT,
  nom_sans_pronom TEXT,
  nom_a TEXT,
  nom_de TEXT,
  nom_sans_accent TEXT,
  nom_standard_majuscule TEXT,
  typecom TEXT,
  typecom_texte TEXT,
  reg_code TEXT,
  reg_nom TEXT,
  dep_code TEXT,
  dep_nom TEXT,
  canton_code TEXT,
  canton_nom TEXT,
  epci_code TEXT,
  epci_nom TEXT,
  academie_code TEXT,
  academie_nom TEXT,
  code_postal TEXT,
  codes_postaux TEXT,
  zone_emploi TEXT,
  code_insee_centre_zone_emploi TEXT,
  code_unite_urbaine TEXT,
  nom_unite_urbaine TEXT,
  taille_unite_urbaine REAL,
  type_commune_unite_urbaine TEXT,
  statut_commune_unite_urbaine TEXT,
  population INTEGER,
  superficie_hectare REAL,
  superficie_km2 REAL,
  densite REAL,
  altitude_moyenne REAL,
  altitude_minimale REAL,
  altitude_maximale REAL,
  latitude_mairie REAL,
  longitude_mairie REAL,
  latitude_centre REAL,
  longitude_centre REAL,
  grille_densite REAL,
  grille_densite_texte TEXT,
  niveau_equipements_services REAL,
  niveau_equipements_services_texte TEXT,
  gentile TEXT,                           -- Nom des habitants
  url_wikipedia TEXT,
  url_villedereve TEXT,
  code_insee_norm TEXT                     -- Normalisé pour jointure
);

-- ================================
-- 3) Table ENRICHIE (jointure)
-- ================================
-- On crée une table matérialisée "incendies_communes"
-- qui combine les données d’incendies avec les attributs
-- géographiques et démographiques des communes.
-- Avantage : éviter de refaire la jointure à chaque requête.
DROP TABLE IF EXISTS incendies_communes;
CREATE TABLE incendies_communes AS
SELECT
  i.*,                                    -- toutes les colonnes des incendies
  c.nom_standard AS commune_ref,          -- nom officiel de la commune
  c.latitude_centre AS lat,               -- latitude du centre
  c.longitude_centre AS lon,              -- longitude du centre
  c.population,                           -- population de la commune
  c.superficie_km2,                       -- superficie en km²
  c.densite                               -- densité de population
FROM incendies i
LEFT JOIN communes c
  ON i.code_insee_norm = c.code_insee_norm;
