#!/usr/bin/env bash
set -euo pipefail

DB="data/csvs/incendies.db"

echo "==> 0) Création/Reset du schéma"
sqlite3 "$DB" ".read sql/01_schema.sql"

echo "==> 1) Import BDIFF (tous les CSV du dossier)"
for f in data/csvs/incendies/*.csv; do
  echo "   - Import $f"
  sqlite3 "$DB" -cmd ".mode csv" -cmd ".separator ;" ".import \"$f\" incendies_stage"
done

echo "==> 2) Import COMMUNES (référentiel)"
sqlite3 "$DB" -cmd ".mode csv" -cmd ".separator ," \
  ".import data/csvs/communes/communes.csv communes_stage"

echo "==> 3) Nettoyage / normalisation"
sqlite3 "$DB" ".read sql/04_cleaning.sql"

echo "==> 4) Jointure (ajout lat/lon)"
sqlite3 "$DB" ".read sql/05_join.sql"

echo "==> 5) Contrôles qualité (résumé)"
sqlite3 -header -column "$DB" ".read sql/06_quality_checks.sql"

echo "==> 6) Vérifs rapides"
sqlite3 "$DB" ".tables"
sqlite3 "$DB" "SELECT COUNT(*) AS n_incendies_stage FROM incendies_stage;"
sqlite3 "$DB" "SELECT COUNT(*) AS n_communes_stage  FROM communes_stage;"
sqlite3 "$DB" "SELECT COUNT(*) AS n_enrichi         FROM incendies_enrichi;"
sqlite3 "$DB" "SELECT ROUND(100.0*SUM(CASE WHEN lat IS NULL OR lon IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_sans_coord FROM incendies_enrichi;"

echo "==> 7) Intégrité de la base"
sqlite3 "$DB" "PRAGMA integrity_check;"
echo "✅ Terminé."
