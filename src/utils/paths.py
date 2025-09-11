#!/usr/bin/env python
# -*- coding: utf-8 -*-
from pathlib import Path

def get_project_root() -> Path:
    """
    Retrouve la racine du projet de façon robuste :
    - si exécuté en tant que script, on remonte depuis __file__
    - sinon (REPL / notebook), on tente depuis cwd
    On remonte jusqu'à trouver un dossier contenant "src" et "data".
    """
    start = None
    try:
        start = Path(__file__).resolve()
    except NameError:
        start = Path.cwd().resolve()

    p = start
    for _ in range(6):  # remonter max 6 niveaux
        if (p / "src").exists() and (p / "data").exists():
            return p
        p = p.parent
    # fallback : cwd
    return Path.cwd().resolve()
