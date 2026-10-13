
-- ============================================================
-- PROJET SQL : Jeu de gestion et economie
-- Fichier : requetes.sql
-- ============================================================


-- ============================================================
-- PALIER 2 : REQUETES ANALYTIQUES
-- ============================================================


-- REQUETE 1 : Classement des batiments selon leur production totale
-- Technique : RANK() et SUM()

SELECT
    b.nom AS batiment,
    SUM(e.quantite) AS production_totale,
    RANK() OVER (
        ORDER BY SUM(e.quantite) DESC
    ) AS classement
FROM batiments b
JOIN evenements_production e
    ON b.id_batiment = e.id_batiment
GROUP BY b.id_batiment, b.nom
ORDER BY production_totale DESC;


-- REQUETE 2 : Top 3 des batiments les plus productifs par categorie
-- Technique : CTE et classement avec PARTITION BY

WITH production AS (
    SELECT
        b.nom AS batiment,
        c.nom AS categorie,
        SUM(e.quantite) AS production_totale
    FROM batiments b
    JOIN categories_batiments c
        ON b.id_categorie = c.id_categorie
    JOIN evenements_production e
        ON b.id_batiment = e.id_batiment
    GROUP BY b.id_batiment, b.nom, c.nom
),
classement AS (
    SELECT
        batiment,
        categorie,
        production_totale,
        RANK() OVER (
            PARTITION BY categorie
            ORDER BY production_totale DESC
        ) AS rang
    FROM production
)
SELECT *
FROM classement
WHERE rang <= 3
ORDER BY categorie, rang;


-- REQUETE 3 : Production cumulee au fil des evenements
-- Technique : SUM() OVER avec une fenetre cumulative

SELECT
    id_evenement,
    date_evenement,
    quantite,
    SUM(quantite) OVER (
        ORDER BY date_evenement, id_evenement
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS production_cumulee
FROM evenements_production
ORDER BY date_evenement, id_evenement;


-- REQUETE 4 : Evolution mensuelle de la production en pourcentage
-- Technique : LAG() et comparaison avec le mois precedent

WITH production_mensuelle AS (
    SELECT
        DATE_TRUNC('month', date_evenement)::date AS mois,
        SUM(quantite) AS production_totale
    FROM evenements_production
    GROUP BY DATE_TRUNC('month', date_evenement)
),
comparaison AS (
    SELECT
        mois,
        production_totale,
        LAG(production_totale) OVER (
            ORDER BY mois
        ) AS production_mois_precedent
    FROM production_mensuelle
)
SELECT
    mois,
    production_totale,
    production_mois_precedent,
    ROUND(
        (
            (production_totale - production_mois_precedent)
            / NULLIF(production_mois_precedent, 0)
        ) * 100,
        2
    ) AS evolution_pourcentage
FROM comparaison
ORDER BY mois;


-- REQUETE 5 : Part de chaque batiment dans la production totale
-- Technique : somme globale avec une fonction fenetre

WITH production AS (
    SELECT
        b.id_batiment,
        b.nom AS batiment,
        SUM(e.quantite) AS production_totale
    FROM batiments b
    JOIN evenements_production e
        ON b.id_batiment = e.id_batiment
    GROUP BY b.id_batiment, b.nom
)
SELECT
    batiment,
    production_totale,
    ROUND(
        production_totale * 100.0
        / NULLIF(SUM(production_totale) OVER (), 0),
        2
    ) AS part_pourcentage
FROM production
ORDER BY production_totale DESC;


-- REQUETE 6 : Moyenne mobile de la production mensuelle
-- Technique : AVG() OVER et fenetre glissante de 3 mois

WITH production_mensuelle AS (
    SELECT
        DATE_TRUNC('month', date_evenement)::date AS mois,
        SUM(quantite) AS production_totale
    FROM evenements_production
    GROUP BY DATE_TRUNC('month', date_evenement)
)
SELECT
    mois,
    production_totale,
    ROUND(
        AVG(production_totale) OVER (
            ORDER BY mois
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moyenne_mobile
FROM production_mensuelle
ORDER BY mois;


-- ============================================================
-- PALIER 3 : CTE ET ANALYSES TEMPORELLES
-- ============================================================


-- REQUETE 7 : CTE enchainees pour identifier les batiments
-- dont la production depasse la production moyenne des batiments

WITH production_batiments AS (
    SELECT
        b.id_batiment,
        b.nom AS batiment,
        SUM(e.quantite) AS production_totale
    FROM batiments b
    JOIN evenements_production e
        ON b.id_batiment = e.id_batiment
    GROUP BY b.id_batiment, b.nom
),
statistiques AS (
    SELECT
        AVG(production_totale) AS production_moyenne
    FROM production_batiments
),
comparaison AS (
    SELECT
        p.batiment,
        p.production_totale,
        s.production_moyenne
    FROM production_batiments p
    CROSS JOIN statistiques s
)
SELECT
    batiment,
    production_totale,
    ROUND(production_moyenne, 2) AS production_moyenne
FROM comparaison
WHERE production_totale > production_moyenne
ORDER BY production_totale DESC;


-- REQUETE 8 : Affichage de la hierarchie des categories
-- Technique : WITH RECURSIVE

WITH RECURSIVE hierarchie AS (
    SELECT
        id_categorie,
        nom,
        id_parent,
        1 AS niveau,
        nom::text AS chemin
    FROM categories_batiments
    WHERE id_parent IS NULL

    UNION ALL

    SELECT
        c.id_categorie,
        c.nom,
        c.id_parent,
        h.niveau + 1,
        h.chemin || ' > ' || c.nom
    FROM categories_batiments c
    JOIN hierarchie h
        ON c.id_parent = h.id_categorie
)
SELECT
    id_categorie,
    nom AS categorie,
    id_parent,
    niveau,
    chemin
FROM hierarchie
ORDER BY chemin;


-- REQUETE 9 : Afficher tous les mois, meme sans production
-- Technique : GENERATE_SERIES et LEFT JOIN

WITH calendrier AS (
    SELECT
        generate_series(
            DATE '2024-01-01',
            DATE '2024-12-01',
            INTERVAL '1 month'
        )::date AS mois
),
production_mensuelle AS (
    SELECT
        DATE_TRUNC('month', date_evenement)::date AS mois,
        SUM(quantite) AS production_totale
    FROM evenements_production
    GROUP BY DATE_TRUNC('month', date_evenement)
)
SELECT
    c.mois,
    COALESCE(p.production_totale, 0) AS production_totale
FROM calendrier c
LEFT JOIN production_mensuelle p
    ON c.mois = p.mois
ORDER BY c.mois;


-- ============================================================
-- PALIER 4 : ANALYSES AVANCEES
-- ============================================================


-- REQUETE 10 : Tableau croise des productions par mois
-- Technique : FILTER

SELECT
    b.nom AS batiment,
    SUM(e.quantite) FILTER (
        WHERE EXTRACT(MONTH FROM e.date_evenement) = 1
    ) AS production_janvier,
    SUM(e.quantite) FILTER (
        WHERE EXTRACT(MONTH FROM e.date_evenement) = 2
    ) AS production_fevrier,
    SUM(e.quantite) FILTER (
        WHERE EXTRACT(MONTH FROM e.date_evenement) = 3
    ) AS production_mars,
    SUM(e.quantite) FILTER (
        WHERE EXTRACT(MONTH FROM e.date_evenement) = 4
    ) AS production_avril,
    SUM(e.quantite) FILTER (
        WHERE EXTRACT(MONTH FROM e.date_evenement) = 5
    ) AS production_mai
FROM batiments b
JOIN evenements_production e
    ON b.id_batiment = e.id_batiment
WHERE e.date_evenement >= DATE '2024-01-01'
  AND e.date_evenement < DATE '2025-01-01'
GROUP BY b.id_batiment, b.nom
ORDER BY b.nom;


-- REQUETE 11 : Totaux par categorie, par batiment et total general
-- Technique : ROLLUP

SELECT
    c.nom AS categorie,
    b.nom AS batiment,
    SUM(e.quantite) AS production_totale
FROM batiments b
JOIN categories_batiments c
    ON b.id_categorie = c.id_categorie
JOIN evenements_production e
    ON b.id_batiment = e.id_batiment
GROUP BY ROLLUP(c.nom, b.nom)
ORDER BY c.nom NULLS LAST, b.nom NULLS LAST;


-- REQUETE 12 : Comparaison de la production moyenne et mediane
-- Technique : AVG() et PERCENTILE_CONT()

SELECT
    b.nom AS batiment,
    COUNT(e.id_evenement) AS nombre_evenements,
    ROUND(AVG(e.quantite), 2) AS production_moyenne,
    ROUND(
        (
            PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY e.quantite)
        )::numeric,
        2
    ) AS production_mediane
FROM batiments b
JOIN evenements_production e
    ON b.id_batiment = e.id_batiment
GROUP BY b.id_batiment, b.nom
ORDER BY production_moyenne DESC;


-- REQUETE 13 : Tableau de bord mensuel de la production
-- Techniques combinees : calendrier, SUM() OVER et moyenne mobile

WITH calendrier AS (
    SELECT
        generate_series(
            DATE '2024-01-01',
            DATE '2024-12-01',
            INTERVAL '1 month'
        )::date AS mois
),
production_mensuelle AS (
    SELECT
        DATE_TRUNC('month', date_evenement)::date AS mois,
        SUM(quantite) AS production_totale
    FROM evenements_production
    GROUP BY DATE_TRUNC('month', date_evenement)
),
donnees_mensuelles AS (
    SELECT
        c.mois,
        COALESCE(p.production_totale, 0) AS production_totale
    FROM calendrier c
    LEFT JOIN production_mensuelle p
        ON c.mois = p.mois
)
SELECT
    mois,
    production_totale,
    SUM(production_totale) OVER (
        ORDER BY mois
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS production_cumulee,
    ROUND(
        AVG(production_totale) OVER (
            ORDER BY mois
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moyenne_mobile_3_mois
FROM donnees_mensuelles
ORDER BY mois;
