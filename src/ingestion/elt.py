#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
ELT minimal : insertion brute + jointure (SQLite)
- Incendies (sep=';')  -> table: incendies_raw
- Communes  (sep=',')  -> table: communes_2025_raw
- Jointure LEFT JOIN sur code INSEE normalisé -> table: incendies_enrichi
"""

from pathlib import Path
# import sys
import csv
import pandas as pd
from sqlalchemy import create_engine

# Paramètres projet (fixes)
DB_PATH     = "data/incendies.db"
INC_ROOT    = "data/csvs/incendies"              # racine des CSV incendies (sous-dossiers OK)
COMM_FILE   = "data/csvs/communes/communes.csv"  # fichier référentiel communes

# Paramètres fichiers
INC_SEP     = ";"
COMM_SEP    = ","
ENCODING    = "utf-8"

# Noms de colonnes pour la jointure
INC_INSEE   = "Code INSEE"   # côté incendies
COMM_INSEE  = "code_insee"   # côté communes




def collect_incendie_files(root: Path) -> list[Path]:
    base = root / INC_ROOT
    files = []
    if base.exists():
        files += list(base.rglob("*.csv"))
        files += list(base.rglob("*.CSV"))
    return sorted(files, key=lambda p: p.name)

def run_elt(root: Path) -> Path:
    """
    Exécute l'ELT complet et renvoie le chemin de la base SQLite.
    """
    db   = (root / DB_PATH).resolve()
    comm = (root / COMM_FILE)

    # DEBUG lisible
    print("=== DEBUG ===")
    print("ROOT     :", root)
    print("INC_ROOT :", root / INC_ROOT)
    print("COMM     :", comm, "| exists:", comm.exists())
    print("===========")

    inc_files = collect_incendie_files(root)
    print("Fichiers incendies détectés:", [f.relative_to(root) for f in inc_files[:8]], "…")
    if not inc_files:
        raise FileNotFoundError(f"Aucun CSV incendies trouvé sous {root / INC_ROOT}")
    if not comm.exists():
        raise FileNotFoundError(f"Fichier communes introuvable : {comm}")

    # Lecture brute (AS-IS)
    inc_frames = []
    for f in inc_files:
        try:
            df = pd.read_csv(f, sep=INC_SEP, engine="python", dtype=str, encoding=ENCODING, quoting=3)
        except Exception as e:
            raise RuntimeError(f"Échec lecture {f}: {e}") from e
        inc_frames.append(df)
        print(f"[inc] {f.relative_to(root)} -> {df.shape}")
    inc_raw = pd.concat(inc_frames, ignore_index=True)
    
    try:
        # com_raw = pd.read_csv(comm, sep=COMM_SEP, engine="python", dtype=str, encoding=ENCODING, quoting=3)
        com_raw = pd.read_csv(comm, 
                              sep=COMM_SEP,          # ","
                              engine="python",
                              dtype=str,
                              encoding=ENCODING,
                              quotechar='"',         # gérer "..." correctement
                              quoting= csv.QUOTE_MINIMAL,  # (valeur par défaut) respecte les champs quotés
                              doublequote=True,      # "" à l’intérieur d’un champ -> traité comme un "
                              on_bad_lines="error"   # ou "warn"/"skip" si tu veux être tolérante 
                              )
        
        # 1) Normalisation des noms de colonnes des deux DataFrames
        strip_name = lambda s: str(s).strip().strip('"').strip("'")
        inc_raw.columns = [strip_name(c) for c in inc_raw.columns]
        com_raw.columns = [strip_name(c) for c in com_raw.columns]
        
    except Exception as e:
        raise RuntimeError(f"Échec lecture {comm}: {e}") from e
    print(f"[com] {comm.relative_to(root)} -> {com_raw.shape}")

    # Écriture RAW
    eng = create_engine(f"sqlite:///{db}")
    with eng.begin() as conn:
        inc_raw.to_sql("incendies_raw", con=conn, if_exists="replace", index=False)
        com_raw.to_sql("communes_2025_raw", con=conn, if_exists="replace", index=False)
        
    # Jointure (normalisation simple de la clé dans des vues)
    # ... après avoir écrit les tables RAW ...

    sql = f"""
    DROP VIEW IF EXISTS incendies_raw_norm;
    DROP VIEW IF EXISTS communes_2025_norm;

    CREATE VIEW incendies_raw_norm AS
    SELECT UPPER(TRIM([{INC_INSEE}])) AS code_insee_norm, * FROM incendies_raw;

    CREATE VIEW communes_2025_norm AS
    SELECT UPPER(TRIM([{COMM_INSEE}])) AS code_insee_norm, * FROM communes_2025_raw;

    DROP TABLE IF EXISTS incendies_enrichi;
    CREATE TABLE incendies_enrichi AS
    SELECT i.*,
        c.[nom_standard] AS commune_nom_standard,
        c.[dep_code]     AS commune_dep_code,
        c.[dep_nom]      AS commune_dep_nom
    FROM incendies_raw_norm i
    LEFT JOIN communes_2025_norm c
    ON i.code_insee_norm = c.code_insee_norm;
    """

    with eng.begin() as conn:
        raw = conn.connection.dbapi_connection  # sqlite3.Connection
        raw.executescript(sql)                  # <<< la ligne clé

    print(f"✅ Base prête : {db}")
    print("   Tables : incendies_raw, communes_2025_raw, incendies_enrichi")
    return db


