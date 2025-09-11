# 🌍🔥 Terre, Vent, Feu, Eau, Data

## 🚨 Contexte
L’été 2025 a été marqué par des incendies historiques en France, dont celui de l’Aude qui a ravagé **17 000 hectares en 48 heures**.  
Face à l’urgence climatique et à la multiplication par 3 de la période à risque d’ici 2050, il est crucial de développer des outils d’intelligence prédictive pour anticiper et prévenir les feux de forêt.  

## 🎯 Objectif du projet
Développer un **prototype d’application** permettant :  
- La **visualisation interactive** des incendies (cartographie, filtres dynamiques, statistiques)  
- La **prédiction du risque d’incendie** par commune et période via un modèle de machine learning  

## 🗄 Données utilisées
- **BDIFF** (Base de Données sur les Incendies de Forêts en France, 1973-2024)  
- **Référentiels géographiques INSEE** (codes INSEE, coordonnées lat/lng des communes)  
- **Sources complémentaires** (surface de végétation, variables contextuelles)  

## 🛠️ Technologies
- **Python** (Pandas, GeoPandas, Scikit-learn)  
- **SQL** (consolidation multi-sources)  
- **Streamlit** (application web interactive)  
- **Folium / Maplibre** (cartographie)  
- **Git & GitHub** (versioning, collaboration)  

## 📊 Fonctionnalités du prototype
### Onglet 1 : Analyse Historique
- Cartographie interactive des incendies  
- Filtres : période, gravité, type de végétation, origine du feu  
- Statistiques descriptives (évolution temporelle, répartition des causes, hotspots)  

### Onglet 2 : Prédiction des Risques
- Modèle de **clustering spatio-temporel** basé sur :  
  - Historique des incendies par commune  
  - Données des communes voisines  
  - Saison et jour de l’année  
- Score de risque par commune et période  



# Dossier `data/` (non versionné)

Placez ici vos fichiers **locaux** (non poussés sur GitHub) :

- `csvs/incendies/*.csv` : exports BDIFF (séparateur `;`, paquets ≤ 30 000 lignes).
- `csvs/communes/communes_2025.csv` : référentiel communes (séparateur `,`) contenant au minimum :
  - code INSEE (colonne: `code_insee` ou `insee`…),
  - latitude (`lat`),
  - longitude (`lon`).

Ces fichiers **ne sont pas** versionnés.

## Téléchargement semi-automatique
Un script d’exemple est fourni :
```bash
python scripts/download_communes.py


## 📅 Organisation du projet
- **Jour 1-2** : Ingestion & consolidation SQL (BDIFF + INSEE)  
- **Jour 3** : Développement application Streamlit  
- **Jour 4** : Modélisation Machine Learning  
- **Jour 5** : Tests finaux, documentation & soutenance  

## 📦 Livrables
- Base SQL consolidée  
- Application Streamlit multi-onglets  
- Modèle prédictif intégré  
- Notebook EDA complet  
- Documentation technique (README, rapport méthodologique)  

## 📚 Références
- [BDIFF – Base Incendies de Forêts](https://bdiff.agriculture.gouv.fr/incendies)  
- [Référentiel Géographique – data.gouv.fr](https://adresse.data.gouv.fr/outils/telechargements)  
- [Documentation Streamlit](https://docs.streamlit.io/)  
- [Clustering spatio-temporel – scikit-learn](https://scikit-learn.org/stable/modules/clustering.html#clustering)  

---
🚀 **Projet pédagogique – Data IA & Environnement**  

