#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Point d'entrée : lance l’ELT (insertion brute + jointure).
Exécution recommandée :  python -m src.app   depuis la racine du projet.
"""

from pathlib import Path
import sys

# Imports relatifs au package 'src'
from .utils.paths import get_project_root
from .ingestion.elt import run_elt

def main() -> None:
    root = get_project_root()
    db_path = run_elt(root)

    print("\nRésumé :")
    print(" - Racine projet :", root)
    print(" - Base SQLite   :", db_path)
    print(" - Tables        : incendies_raw, communes_2025_raw, incendies_enrichi")

if __name__ == "__main__":
    # Petit garde-fou : montrer le sys.path si besoin de debug
    # print("sys.path:", sys.path)
    main()
