# streamlit_app.py
# ----------------------------------------------------
# Terre, Vent, Feu, Eau, Data — Prototype Streamlit
# Onglet 1 : Historique & EDA
# Onglet 2 : Prédiction (baseline RandomForest)
# ----------------------------------------------------
# Exécution : streamlit run streamlit_app.py
# Dépendances : voir requirements.txt
# ----------------------------------------------------

import sqlite3
from pathlib import Path
import numpy as np
import pandas as pd
import streamlit as st
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score

st.set_page_config(page_title="Incendies — Prototype", layout="wide")

# ==============================
# Config
# ==============================
DB_PATH_DEFAULT = "data/incendies.db"  # à adapter si besoin
TABLE_DEFAULT   = "incendies"          # à adapter si besoin

# ==============================
# Helpers
# ==============================
def normalize_cols(columns):
    repl = ((" ", "_"), ("é","e"), ("è","e"), ("ê","e"), ("à","a"),
            ("ô","o"), ("û","u"), ("(",""), (")",""))
    out = []
    for c in columns:
        cc = c.strip().lower()
        for a,b in repl:
            cc = cc.replace(a,b)
        out.append(cc)
    return out

@st.cache_data(show_spinner=False)
def load_table(db_path: str, table_name: str, limit: int|None=None) -> pd.DataFrame:
    con = sqlite3.connect(db_path)
    q = f"SELECT * FROM {table_name}" + (f" LIMIT {limit}" if limit else "") + ";"
    df = pd.read_sql(q, con)
    con.close()
    # normalize cols
    df.columns = normalize_cols(df.columns)
    # detect date col
    date_candidates = [c for c in df.columns if 'date' in c or 'alerte' in c]
    date_col = None
    for c in date_candidates:
        try:
            pd.to_datetime(df[c], errors="raise")
            date_col = c
            break
        except Exception:
            continue
    if date_col is None and date_candidates:
        date_col = date_candidates[0]
    if date_col:
        df[date_col] = pd.to_datetime(df[date_col], errors="coerce")
        df['annee'] = df[date_col].dt.year
        df['mois']  = df[date_col].dt.month
        df['jour']  = df[date_col].dt.day
        df['jour_annee'] = df[date_col].dt.dayofyear
    # identify surfaces
    surface_cols = [c for c in df.columns if 'surface' in c]
    for c in surface_cols:
        df[c] = pd.to_numeric(df[c], errors='coerce')
    if surface_cols:
        df['surface_totale'] = df[surface_cols].sum(axis=1)
    else:
        df['surface_totale'] = np.nan
    return df

def train_baseline_model(df: pd.DataFrame) -> tuple[RandomForestClassifier, list[str]]:
    # features
    surface_cols = [c for c in df.columns if 'surface' in c]
    feature_cols = []
    feature_cols += surface_cols
    for c in ['annee','mois']:
        if c in df.columns:
            feature_cols.append(c)
    if 'mois' in df.columns:
        df['sin_mois'] = np.sin(2*np.pi*df['mois']/12)
        df['cos_mois'] = np.cos(2*np.pi*df['mois']/12)
        feature_cols += ['sin_mois','cos_mois']

    # target
    if 'surface_totale' not in df.columns:
        return None, []
    y = (df['surface_totale'] > 1000).astype(int)  # cible binaire

    # X
    X = df[feature_cols].copy().fillna(0)
    if X.empty or y.nunique() != 2:
        return None, feature_cols

    # split/train
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    rf = RandomForestClassifier(n_estimators=250, random_state=42, n_jobs=-1)
    rf.fit(X_train, y_train)

    # quick metrics
    y_pred = rf.predict(X_test)
    y_proba = rf.predict_proba(X_test)[:,1]
    auc = roc_auc_score(y_test, y_proba)
    cm = confusion_matrix(y_test, y_pred)

    st.caption(f"Baseline RandomForest — ROC-AUC = **{auc:.3f}**")
    st.caption(f"Matrice de confusion : TN={cm[0,0]} FP={cm[0,1]} FN={cm[1,0]} TP={cm[1,1]}")

    return rf, feature_cols

def has_latlng(df: pd.DataFrame) -> bool:
    lat_candidates = [c for c in df.columns if c in ['lat','latitude']]
    lng_candidates = [c for c in df.columns if c in ['lng','lon','longitude']]
    return len(lat_candidates)>0 and len(lng_candidates)>0

# ==============================
# Sidebar — paramètres
# ==============================
st.sidebar.header("⚙️ Configuration")
db_path = st.sidebar.text_input("Chemin base SQLite", value=DB_PATH_DEFAULT)
table_name = st.sidebar.text_input("Nom de la table", value=TABLE_DEFAULT)
limit_rows = st.sidebar.number_input("Limite de chargement (0 = tout)", min_value=0, value=0, step=10000)
st.sidebar.info("Astuce : garde une limite si la table est très volumineuse.")

if not Path(db_path).exists():
    st.error(f"Base introuvable : {db_path}")
    st.stop()

# ==============================
# Load data
# ==============================
df = load_table(db_path, table_name, None if limit_rows==0 else int(limit_rows))
if df.empty:
    st.warning("La table est vide ou introuvable.")
    st.stop()

# ==============================
# Tabs
# ==============================
tab1, tab2 = st.tabs(["📊 Historique & EDA", "🔮 Prédiction"])

# --------------------------------
# Tab 1 — Historique & EDA
# --------------------------------
with tab1:
    st.subheader("Vue d'ensemble")
    c1, c2, c3, c4 = st.columns(4)
    with c1:
        st.metric("Lignes", len(df))
    with c2:
        st.metric("Colonnes", df.shape[1])
    with c3:
        st.metric("Années uniques", df['annee'].nunique() if 'annee' in df.columns else 0)
    with c4:
        st.metric("Surface médiane (m²)", f"{np.nanmedian(df['surface_totale']):,.0f}" if 'surface_totale' in df.columns else "N/A")

    # Filtres
    st.markdown("### Filtres")
    cols_filter = st.columns(3)
    if 'annee' in df.columns:
        annee_min = int(df['annee'].min())
        annee_max = int(df['annee'].max())
        annee_range = cols_filter[0].slider("Année", annee_min, annee_max, (annee_min, annee_max))
    else:
        annee_range = None

    dept_col_candidates = [c for c in df.columns if c in ['departement','code_departement','dept','code_dept']]
    dcol = dept_col_candidates[0] if dept_col_candidates else None
    if dcol:
        depts = ["(tous)"] + sorted(df[dcol].dropna().astype(str).unique().tolist())
        dept_sel = cols_filter[1].selectbox("Département", options=depts, index=0)
    else:
        dept_sel = "(tous)"

    severite_threshold = float(cols_filter[2].number_input("Seuil incendie majeur (m²)", min_value=0.0, value=1000.0, step=100.0))

    # Application des filtres
    df_f = df.copy()
    if annee_range and 'annee' in df_f.columns:
        df_f = df_f[(df_f['annee']>=annee_range[0]) & (df_f['annee']<=annee_range[1])]
    if dcol and dept_sel != "(tous)":
        df_f = df_f[df_f[dcol].astype(str) == str(dept_sel)]
    if 'surface_totale' in df_f.columns:
        df_f['incendie_majeur'] = (df_f['surface_totale'] > severite_threshold).astype(int)

    st.dataframe(df_f.head(200))

    st.markdown("### Tendances")
    # Incendies par année
    if 'annee' in df_f.columns and len(df_f):
        counts = df_f.groupby('annee').size()
        fig, ax = plt.subplots()
        counts.plot(ax=ax, marker='o')
        ax.set_title("Nombre d'incendies par année")
        ax.grid(True)
        st.pyplot(fig)

    # Répartition majeure / non-majeur
    if 'incendie_majeur' in df_f.columns:
        pie_data = df_f['incendie_majeur'].value_counts().sort_index()
        labels = ["Non-majeur","Majeur"]
        fig, ax = plt.subplots()
        ax.pie(pie_data.values, labels=labels[:len(pie_data)], autopct='%1.1f%%')
        ax.set_title("Répartition des incendies (seuil)")
        st.pyplot(fig)

    # Carte si lat/lng
    st.markdown("### Carte")
    if has_latlng(df_f):
        lat_col = 'lat' if 'lat' in df_f.columns else 'latitude'
        lng_col = 'lng' if 'lng' in df_f.columns else ('lon' if 'lon' in df_f.columns else 'longitude')
        st.map(df_f[[lat_col,lng_col]].dropna().rename(columns={lat_col:'lat', lng_col:'lon'}))
    else:
        st.info("Colonnes latitude/longitude non détectées — affichage carte désactivé.")

# --------------------------------
# Tab 2 — Prédiction
# --------------------------------
with tab2:
    st.subheader("Prédiction du risque (baseline)")
    st.caption("Modèle simple entraîné à la volée sur les données chargées. À remplacer par un modèle entraîné/offline pour la production.")

    rf, feature_cols = train_baseline_model(df)
    if rf is None or not feature_cols:
        st.warning("Impossible d'entraîner le modèle avec les données actuelles (features/cible insuffisantes).")
        st.stop()

    # Sélection commune / mois
    commune_col_candidates = [c for c in df.columns if c in ['nom_de_la_commune','commune','nom_commune']]
    ccol = commune_col_candidates[0] if commune_col_candidates else None
    if ccol:
        communes = ["(toutes)"] + sorted(df[ccol].dropna().astype(str).unique().tolist())
        commune_sel = st.selectbox("Commune", options=communes, index=0)
    else:
        commune_sel = "(toutes)"

    mois_sel = st.slider("Mois", 1, 12, 8)

    # Caractéristiques d'entrée : médianes par commune si dispo, sinon globales
    base = df.copy()
    if ccol and commune_sel != "(toutes)":
        base = base[base[ccol].astype(str) == str(commune_sel)]

    # créer un vecteur d'entrée
    x = {}
    for c in feature_cols:
        if c in ['mois','annee','sin_mois','cos_mois']:
            # nous recalculons mois & features cycliques
            continue
        # surfaces → médiane historique
        x[c] = float(np.nanmedian(base[c])) if c in base.columns else 0.0

    # ajouter dimensions temporelles
    x['mois'] = mois_sel if 'mois' in feature_cols else 0
    if 'annee' in feature_cols:
        # prendre l'année la plus récente si disponible
        x['annee'] = int(np.nanmax(df['annee'])) if 'annee' in df.columns else 0
    if 'sin_mois' in feature_cols:
        x['sin_mois'] = np.sin(2*np.pi*mois_sel/12)
    if 'cos_mois' in feature_cols:
        x['cos_mois'] = np.cos(2*np.pi*mois_sel/12)

    X_input = pd.DataFrame([x], columns=feature_cols).fillna(0)

    # Prédiction
    proba = rf.predict_proba(X_input)[:,1][0]
    pred  = int(proba >= 0.5)

    st.metric("Score de risque (proba)", f"{proba*100:.1f}%")
    st.write("Classe prédite :", "🔥 **Majeur**" if pred==1 else "🟢 Non-majeur")

    st.caption("⚠️ Prototype : les features ici sont des médianes historiques (commune sélectionnée) + mois choisi.")
    st.caption("Pour une version avancée : intégrer météo, voisinage, surfaces végétales, validation géographique, calibration, etc.")
