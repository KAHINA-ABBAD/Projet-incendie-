-- ===========================================
-- Projet   : Terre, Vent, Feu, Eau, Data
-- Auteur   : Kahina ABBAD
-- Objectif : Normaliser les codes INSEE
-- ===========================================

-- Pourquoi la normalisation ?
-- ============================
-- Dans les fichiers CSV, les codes INSEE ne sont pas toujours homogènes :
--  - parfois "123" au lieu de "00123"
--  - parfois avec des espaces en trop " 75056"
--  - parfois en minuscules (pour d’autres champs)
--
-- Si on garde les valeurs brutes, la jointure entre
-- la table "incendies" et la table "communes" risque
-- de rater beaucoup de correspondances, et donc de
-- produire des lignes sans latitude/longitude.
--
-- La solution est de "normaliser" les codes INSEE :
--  - supprimer les espaces
--  - forcer sur 5 caractères (avec des zéros devant)
--  - conserver le format texte (TEXT) car certains codes
--    commencent par une lettre (ex : 2A pour la Corse).
--
-- Exemple :
--   brut   → "123"
--   normé  → "00123"
--
--   brut   → " 75056"
--   normé  → "75056"
-- ===========================================
-- Ajouter la colonne si elle n’existe pas déjà
ALTER TABLE incendies ADD COLUMN code_insee_norm TEXT;
ALTER TABLE communes ADD COLUMN code_insee_norm TEXT;

-- Normaliser les codes INSEE des incendies
UPDATE incendies
SET code_insee_norm = substr('00000' || trim("Code INSEE"), -5);

-- Normaliser les codes INSEE des communes
UPDATE communes
SET code_insee_norm = substr('00000' || trim(code_insee), -5);

-- Vérification rapide
-- (affiche 10 codes bruts et normalisés pour contrôle)
-- Vérification rapide
SELECT "Code INSEE", code_insee_norm
FROM incendies
LIMIT 10;

SELECT code_insee, code_insee_norm
FROM communes
LIMIT 10;
