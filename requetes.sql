-- PROJET SQL : Jeu de gestion et économie
-- Les quantités se comparent par ressource : on ne somme pas des kg et des litres.

-- PALIER 2 : FONCTIONS DE FENÊTRE

-- Q1 : Quel est le classement des bâtiments pour chaque ressource produite ?
-- RANK conserve les ex aequo ; la partition utilise l'identifiant de ressource.
SELECT r.nom AS ressource, r.unite, b.nom AS batiment,
       SUM(e.quantite) AS production_totale,
       RANK() OVER (
           PARTITION BY r.id_ressource ORDER BY SUM(e.quantite) DESC
       ) AS classement
FROM evenements_production e
JOIN batiments b USING (id_batiment)
JOIN ressources r USING (id_ressource)
GROUP BY r.id_ressource, r.nom, r.unite, b.id_batiment, b.nom
ORDER BY r.nom, classement, b.id_batiment;

-- Q2 : Quels sont les trois premiers bâtiments de chaque catégorie, par ressource ?
-- Deux CTE enchaînées. RANK peut retourner plus de trois bâtiments en cas d'ex aequo.
WITH production AS (
    SELECT b.id_batiment, b.nom AS batiment,
           c.id_categorie, c.nom AS categorie,
           r.id_ressource, r.nom AS ressource, r.unite,
           SUM(e.quantite) AS production_totale
    FROM batiments b
    JOIN categories_batiments c USING (id_categorie)
    JOIN evenements_production e USING (id_batiment)
    JOIN ressources r USING (id_ressource)
    GROUP BY b.id_batiment, b.nom, c.id_categorie, c.nom,
             r.id_ressource, r.nom, r.unite
), classement AS (
    SELECT *, RANK() OVER (
        PARTITION BY id_categorie, id_ressource ORDER BY production_totale DESC
    ) AS rang
    FROM production
)
SELECT categorie, ressource, unite, batiment, production_totale, rang
FROM classement
WHERE rang <= 3
ORDER BY categorie, ressource, rang, id_batiment;

-- Q3 : Comment la production cumulée évolue-t-elle pour chaque ressource ?
-- L'identifiant départage deux événements ayant exactement la même date.
SELECT r.nom AS ressource, r.unite, e.id_evenement, e.date_evenement, e.quantite,
       SUM(e.quantite) OVER (
           PARTITION BY e.id_ressource ORDER BY e.date_evenement, e.id_evenement
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS production_cumulee
FROM evenements_production e
JOIN ressources r USING (id_ressource)
ORDER BY r.nom, e.date_evenement, e.id_evenement;

-- Q4 : Quelle est l'évolution par rapport au mois précédent, par ressource ?
-- Le calendrier inclut les mois vides entre le premier et le dernier événement.
-- NULL signifie : aucun mois précédent, ou pourcentage indéfini après un zéro.
WITH calendrier AS (
    SELECT generate_series(
        DATE_TRUNC('month', MIN(date_evenement)),
        DATE_TRUNC('month', MAX(date_evenement)), INTERVAL '1 month'
    )::date AS mois
    FROM evenements_production
), production_mensuelle AS (
    SELECT r.id_ressource, r.nom AS ressource, r.unite, c.mois,
           COALESCE(SUM(e.quantite), 0) AS production_totale
    FROM ressources r CROSS JOIN calendrier c
    LEFT JOIN evenements_production e
        ON e.id_ressource = r.id_ressource
       AND e.date_evenement >= c.mois
       AND e.date_evenement < c.mois + INTERVAL '1 month'
    GROUP BY r.id_ressource, r.nom, r.unite, c.mois
), comparaison AS (
    SELECT *, LAG(production_totale) OVER (
        PARTITION BY id_ressource ORDER BY mois
    ) AS production_mois_precedent
    FROM production_mensuelle
)
SELECT ressource, unite, mois, production_totale, production_mois_precedent,
       ROUND(100.0 * (production_totale - production_mois_precedent)
             / NULLIF(production_mois_precedent, 0), 2) AS evolution_pourcentage
FROM comparaison
ORDER BY ressource, mois;

-- Q5 : Quelle part de la production d'une ressource revient à chaque bâtiment ?
WITH production AS (
    SELECT b.id_batiment, b.nom AS batiment,
           r.id_ressource, r.nom AS ressource, r.unite,
           SUM(e.quantite) AS production_totale
    FROM evenements_production e
    JOIN batiments b USING (id_batiment)
    JOIN ressources r USING (id_ressource)
    GROUP BY b.id_batiment, b.nom, r.id_ressource, r.nom, r.unite
)
SELECT ressource, unite, batiment, production_totale,
       ROUND(production_totale * 100.0 / NULLIF(
           SUM(production_totale) OVER (PARTITION BY id_ressource), 0
       ), 2) AS part_pourcentage
FROM production
ORDER BY ressource, production_totale DESC, id_batiment;

-- Q6 : Quelle est la moyenne mobile sur trois mois, par ressource ?
-- Les mois sans production valent zéro ; au début, la fenêtre contient 1 puis 2 mois.
WITH calendrier AS (
    SELECT generate_series(
        DATE_TRUNC('month', MIN(date_evenement)),
        DATE_TRUNC('month', MAX(date_evenement)), INTERVAL '1 month'
    )::date AS mois
    FROM evenements_production
), production_mensuelle AS (
    SELECT r.id_ressource, r.nom AS ressource, r.unite, c.mois,
           COALESCE(SUM(e.quantite), 0) AS production_totale
    FROM ressources r CROSS JOIN calendrier c
    LEFT JOIN evenements_production e
        ON e.id_ressource = r.id_ressource
       AND e.date_evenement >= c.mois
       AND e.date_evenement < c.mois + INTERVAL '1 month'
    GROUP BY r.id_ressource, r.nom, r.unite, c.mois
)
SELECT ressource, unite, mois, production_totale,
       ROUND(AVG(production_totale) OVER (
           PARTITION BY id_ressource ORDER BY mois
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS moyenne_mobile
FROM production_mensuelle
ORDER BY ressource, mois;

-- PALIER 3 : CTE ET RÉCURSIVITÉ

-- Q7 : Quels bâtiments dépassent la moyenne des producteurs d'une même ressource ?
-- Deux CTE enchaînées, en plus de celles de Q2 : statistiques dépend de production.
-- La moyenne porte sur les bâtiments ayant produit cette ressource sur la période.
WITH production AS (
    SELECT b.id_batiment, b.nom AS batiment,
           r.id_ressource, r.nom AS ressource, r.unite,
           SUM(e.quantite) AS production_totale
    FROM evenements_production e
    JOIN batiments b USING (id_batiment)
    JOIN ressources r USING (id_ressource)
    GROUP BY b.id_batiment, b.nom, r.id_ressource, r.nom, r.unite
), statistiques AS (
    SELECT id_ressource, AVG(production_totale) AS production_moyenne
    FROM production GROUP BY id_ressource
)
SELECT p.ressource, p.unite, p.batiment, p.production_totale,
       ROUND(s.production_moyenne, 2) AS production_moyenne
FROM production p JOIN statistiques s USING (id_ressource)
WHERE p.production_totale > s.production_moyenne
ORDER BY p.ressource, p.production_totale DESC, p.id_batiment;

-- Q8 : Quelle est la hiérarchie complète des catégories, avec niveau et chemin ?
WITH RECURSIVE hierarchie AS (
    SELECT id_categorie, nom, id_parent, 1 AS niveau, nom::text AS chemin
    FROM categories_batiments WHERE id_parent IS NULL
    UNION ALL
    SELECT c.id_categorie, c.nom, c.id_parent, h.niveau + 1,
           h.chemin || ' > ' || c.nom
    FROM categories_batiments c JOIN hierarchie h ON c.id_parent = h.id_categorie
)
SELECT id_categorie, nom AS categorie, id_parent, niveau, chemin
FROM hierarchie ORDER BY chemin, id_categorie;

-- Q9 : Quels mois de 2024 sont sans activité pour chaque ressource ?
-- Année d'étude explicite : juin à décembre sont conservés même sans événements.
WITH calendrier AS (
    SELECT generate_series(TIMESTAMP '2024-01-01', TIMESTAMP '2024-12-01',
                           INTERVAL '1 month')::date AS mois
), production_mensuelle AS (
    SELECT id_ressource, DATE_TRUNC('month', date_evenement)::date AS mois,
           SUM(quantite) AS production_totale
    FROM evenements_production
    GROUP BY id_ressource, DATE_TRUNC('month', date_evenement)
)
SELECT r.nom AS ressource, r.unite, c.mois,
       COALESCE(p.production_totale, 0) AS production_totale
FROM ressources r CROSS JOIN calendrier c
LEFT JOIN production_mensuelle p ON p.mois = c.mois AND p.id_ressource = r.id_ressource
ORDER BY r.nom, c.mois;

-- PALIER 4 : RAPPORTS D'AGRÉGATION

-- Q10 : Quelle quantité chaque bâtiment produit-il de janvier à mai 2024, par ressource ?
-- Les mois vides affichent 0. L'année est filtrée pour ne pas mélanger plusieurs années.
SELECT b.nom AS batiment, r.nom AS ressource, r.unite,
       COALESCE(SUM(e.quantite) FILTER (WHERE EXTRACT(MONTH FROM e.date_evenement) = 1), 0) AS production_janvier,
       COALESCE(SUM(e.quantite) FILTER (WHERE EXTRACT(MONTH FROM e.date_evenement) = 2), 0) AS production_fevrier,
       COALESCE(SUM(e.quantite) FILTER (WHERE EXTRACT(MONTH FROM e.date_evenement) = 3), 0) AS production_mars,
       COALESCE(SUM(e.quantite) FILTER (WHERE EXTRACT(MONTH FROM e.date_evenement) = 4), 0) AS production_avril,
       COALESCE(SUM(e.quantite) FILTER (WHERE EXTRACT(MONTH FROM e.date_evenement) = 5), 0) AS production_mai
FROM evenements_production e
JOIN batiments b USING (id_batiment)
JOIN ressources r USING (id_ressource)
WHERE e.date_evenement >= DATE '2024-01-01' AND e.date_evenement < DATE '2024-06-01'
GROUP BY b.id_batiment, b.nom, r.id_ressource, r.nom, r.unite
ORDER BY b.nom, r.nom, b.id_batiment;

-- Q11 : Quels sont les totaux par bâtiment, catégorie et ressource ?
-- ROLLUP conserve un total par ressource ; aucun total entre ressources différentes.
-- Les identifiants distinguent les homonymes, GROUPING identifie les sous-totaux.
SELECT r.nom AS ressource, r.unite,
       CASE WHEN GROUPING(c.id_categorie) = 1 THEN 'Toutes les catégories'
            ELSE c.nom END AS categorie,
       CASE WHEN GROUPING(c.id_categorie) = 1 THEN 'TOTAL RESSOURCE'
            WHEN GROUPING(b.id_batiment) = 1 THEN 'Sous-total catégorie'
            ELSE b.nom END AS batiment,
       SUM(e.quantite) AS production_totale
FROM evenements_production e
JOIN batiments b USING (id_batiment)
JOIN categories_batiments c USING (id_categorie)
JOIN ressources r USING (id_ressource)
GROUP BY r.id_ressource, r.nom, r.unite,
         ROLLUP((c.id_categorie, c.nom), (b.id_batiment, b.nom))
ORDER BY r.nom, GROUPING(c.id_categorie), c.id_categorie,
         GROUPING(b.id_batiment), b.id_batiment;

-- Q12 : La moyenne et la médiane des quantités diffèrent-elles, par bâtiment et ressource ?
SELECT b.nom AS batiment, r.nom AS ressource, r.unite,
       COUNT(*) AS nombre_evenements,
       ROUND(AVG(e.quantite), 2) AS production_moyenne,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.quantite)::numeric, 2) AS production_mediane
FROM evenements_production e
JOIN batiments b USING (id_batiment)
JOIN ressources r USING (id_ressource)
GROUP BY b.id_batiment, b.nom, r.id_ressource, r.nom, r.unite
ORDER BY r.nom, production_moyenne DESC, b.id_batiment;

-- Q13 : Tableau de bord direction : totaux, cumul et moyenne mobile par ressource en 2024.
-- Combine calendrier, LEFT JOIN, CTE enchaînées et deux fonctions de fenêtre.
WITH calendrier AS (
    SELECT generate_series(TIMESTAMP '2024-01-01', TIMESTAMP '2024-12-01',
                           INTERVAL '1 month')::date AS mois
), donnees_mensuelles AS (
    SELECT r.id_ressource, r.nom AS ressource, r.unite, c.mois,
           COALESCE(SUM(e.quantite), 0) AS production_totale
    FROM ressources r CROSS JOIN calendrier c
    LEFT JOIN evenements_production e
        ON e.id_ressource = r.id_ressource
       AND e.date_evenement >= c.mois
       AND e.date_evenement < c.mois + INTERVAL '1 month'
    GROUP BY r.id_ressource, r.nom, r.unite, c.mois
)
SELECT ressource, unite, mois, production_totale,
       SUM(production_totale) OVER (
           PARTITION BY id_ressource ORDER BY mois
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS production_cumulee,
       ROUND(AVG(production_totale) OVER (
           PARTITION BY id_ressource ORDER BY mois
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS moyenne_mobile_3_mois
FROM donnees_mensuelles
ORDER BY ressource, mois;
