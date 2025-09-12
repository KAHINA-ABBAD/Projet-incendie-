.PHONY: setup run test clean

setup:
	# Crée l'environnement virtuel et installe les dépendances
	python -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt

run:
	# Commande pour exécuter ton projet principal
	python scripts/main.py

test:
	# Lancer les tests unitaires
	pytest -q

clean:
	# Nettoyer les fichiers temporaires
	rm -rf __pycache__ .pytest_cache
