-- Classe les bâtiments selon leur production totale
SELECT
    b.nom,
    SUM(e.quantite) AS production_totale,
    RANK() OVER (ORDER BY SUM(e.quantite) DESC) AS classement
FROM batiments b
JOIN evenements_production e
    ON b.id_batiment = e.id_batiment
GROUP BY b.nom
ORDER BY production_totale DESC;

-- Affiche les trois bâtiments les plus productifs de chaque catégorie
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