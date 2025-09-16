# ============================================================
# Application Streamlit : Analyse des incendies
# ============================================================
# Ce script permet :
# - d’explorer les incendies via une carte et quelques graphiques (EDA)
# - de tester un modèle prédictif pour savoir si un incendie est grave
# ============================================================

import sqlite3
import numpy as np
import pandas as pd
import joblib
import streamlit as st
import matplotlib.pyplot as plt
import seaborn as sns

from datetime import datetime
from streamlit_folium import st_folium
import folium
from folium import plugins

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------
DB_PATH   = "data/incendies.db"           # Base SQLite
TABLE     = "incendies_propres"           # Table avec données nettoyées
P_PREP    = "models/preprocessor.pkl"     # Préprocesseur sauvegardé
P_MODEL   = "models/modele_foret.pkl"     # Modèle entraîné

st.set_page_config(page_title="🔥 Incendies en France", layout="wide")

# ------------------------------------------------------------
# FONCTIONS UTILES
# ------------------------------------------------------------
def load_sql(table, where="", limit=None):
    """Charge une table SQLite avec clause WHERE et LIMIT optionnels."""
    con = sqlite3.connect(DB_PATH)
    q = f"SELECT * FROM {table}"
    if where: q += f" WHERE {where}"
    if limit: q += f" LIMIT {limit}"
    df = pd.read_sql(q, con)
    con.close()
    return df

def load_artifacts():
    """Charge le préprocesseur et le modèle si dispo."""
    try:
        preproc = joblib.load(P_PREP)
        model   = joblib.load(P_MODEL)
        return preproc, model
    except:
        return None, None

# ------------------------------------------------------------
# ONGLET 1 : EDA & CARTES
# ------------------------------------------------------------
tab1, tab2 = st.tabs(["🗺️ Exploration", "🔮 Prédiction"])

with tab1:
    st.title("🗺️ Exploration des incendies")

    # Charger quelques données pour voir les colonnes
    df_head = load_sql(TABLE, limit=5)

    if df_head.empty:
        st.error("⚠️ Impossible de charger la table. Vérifie TABLE et DB_PATH.")
    else:
        # Filtres simples
        an_min = int(load_sql(TABLE)[ "annee"].min())
        an_max = int(load_sql(TABLE)[ "annee"].max())
        annee_sel = st.slider("Années", min_value=an_min, max_value=an_max, value=(an_min, an_max))
        
        # Charger données filtrées
        df = load_sql(TABLE, where=f"annee BETWEEN {annee_sel[0]} AND {annee_sel[1]}")
        
        st.write(f"**{len(df)} incendies sélectionnés**")

        # --------------------
        # Carte Folium
        # --------------------
        if "latitude" in df.columns and "longitude" in df.columns:
            m = folium.Map(location=[46.5, 2.5], zoom_start=6, tiles="CartoDB positron", control_scale=True)
            cluster = plugins.MarkerCluster().add_to(m)

            for _, row in df.sample(min(1000, len(df)), random_state=42).iterrows():
                grav_color = "red" if row.get("gravite",0)==1 else "blue"
                folium.CircleMarker(
                    location=[row["latitude"], row["longitude"]],
                    radius=4,
                    color=grav_color,
                    fill=True,
                    fill_color=grav_color,
                    fill_opacity=0.6,
                    popup=f"Année: {row['annee']}<br>Surface: {row['surface_brulee_m2']} m²"
                ).add_to(cluster)

            st_folium(m, height=500, use_container_width=True)

        # --------------------
        # Graphiques simples
        # --------------------
        st.subheader("📊 Statistiques")
        c1, c2 = st.columns(2)

        with c1:
            fig, ax = plt.subplots()
            df.groupby("annee").size().plot(ax=ax, marker="o")
            ax.set_title("Nombre d'incendies par année")
            st.pyplot(fig)

        with c2:
            fig, ax = plt.subplots()
            sns.histplot(np.log10(df["surface_brulee_m2"].clip(lower=1)), bins=30, ax=ax)
            ax.set_title("Distribution log10(surface brûlée)")
            st.pyplot(fig)

# ------------------------------------------------------------
# ONGLET 2 : PREDICTION
# ------------------------------------------------------------
with tab2:
    st.title("🔮 Prédire la gravité d’un incendie")

    preproc, model = load_artifacts()
    if not preproc or not model:
        st.error("⚠️ Modèle ou préprocesseur introuvable. Vérifie tes fichiers.")
    else:
        mode = st.radio("Mode :", ["Depuis la base", "Saisie manuelle"], horizontal=True)

        # -----------------------
        # MODE 1 : Depuis la base
        # -----------------------
        if mode == "Depuis la base":
            df_all = load_sql(TABLE, limit=50000)

            if "commune_ref" in df_all.columns:
                # Liste des communes disponibles
                communes = sorted(df_all["commune_ref"].dropna().unique())
                commune_choice = st.selectbox("Choisir une commune", communes)

                # Filtrer les incendies de cette commune
                df_com = df_all[df_all["commune_ref"] == commune_choice]
                st.write(f"**{len(df_com)} incendies trouvés dans {commune_choice}**")

                # Créer une description lisible pour chaque incendie
                df_com["description"] = (
                    "Année: " + df_com["annee"].astype(str) +
                    " | Surface: " + df_com["surface_brulee_m2"].astype(str) + " m²" +
                    " | Gravité: " + df_com["gravite"].map({0: "Non grave", 1: "Grave"}).astype(str)
                )

                # Sélection d’un incendie via description
                choice = st.selectbox("Choisir un incendie :", df_com["description"])
                x_row = df_com.loc[df_com["description"] == choice]

                # Afficher l’incendie choisi
                st.write("📌 Incendie sélectionné :", x_row)

                # Prédiction
                try:
                    Xt = preproc.transform(x_row)
                    proba = model.predict_proba(Xt)[0, 1]
                    pred = int(proba >= 0.5)
                    st.metric("Probabilité (grave)", f"{proba:.2f}")
                    st.metric("Prédiction", "🔥 Grave" if pred == 1 else "✅ Non grave")
                except Exception as e:
                    st.error(f"Erreur de prédiction : {e}")
            else:
                st.error("La colonne 'commune_ref' est introuvable dans la table.")

        # -----------------------
        # MODE 2 : Saisie manuelle
        # -----------------------
        else:
            with st.form("form_pred"):
                annee = st.number_input("Année", 1973, 2100, 2025)
                mois  = st.selectbox("Mois", list(range(1, 13)), index=0)
                jour  = st.selectbox("Jour", list(range(1, 32)), index=0)
                heure = st.selectbox("Heure", list(range(24)), index=12)
                type_peupl = st.selectbox(
                    "Type peuplement",
                    ["Landes/garrigues/maquis", "Taillis", "Futaies feuillues", "Futaies résineuses"]
                )
                commune = st.text_input("Commune (commune_ref)", "Marseille")

                submit = st.form_submit_button("Prédire")

            if submit:
                try:
                    x_row = pd.DataFrame([{
                        "annee": annee,
                        "mois": mois,
                        "jour": jour,
                        "heure": heure,
                        "type_peuplement": type_peupl,
                        "commune_ref": commune
                    }])
                    Xt = preproc.transform(x_row)
                    proba = model.predict_proba(Xt)[0, 1]
                    pred = int(proba >= 0.5)
                    st.success(f"Probabilité (grave) = {proba:.2f} → "
                               f"**{'🔥 Grave' if pred == 1 else '✅ Non grave'}**")
                except Exception as e:
                    st.error(f"Erreur de prédiction : {e}")
