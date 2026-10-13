-- À exécuter après schema.sql et seed.sql. Ces contrôles ne modifient pas les données.
-- Une exception signale un critère obligatoire non satisfait.
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM ressources) < 15
       OR (SELECT COUNT(*) FROM categories_batiments) < 15
       OR (SELECT COUNT(*) FROM batiments) < 15 THEN
        RAISE EXCEPTION 'Palier 1 : au moins 15 lignes par table principale sont nécessaires';
    END IF;
    IF (SELECT COUNT(*) FROM evenements_production) < 100 THEN
        RAISE EXCEPTION 'Palier 1 : au moins 100 événements sont nécessaires';
    END IF;
    IF (SELECT COUNT(DISTINCT DATE_TRUNC('month', date_evenement))
        FROM evenements_production) < 3 THEN
        RAISE EXCEPTION 'Palier 1 : les événements doivent couvrir au moins trois mois';
    END IF;
    IF EXISTS (
        SELECT 1 FROM evenements_production WHERE quantite <= 0 OR quantite IS NULL
    ) THEN
        RAISE EXCEPTION 'Une quantité est nulle ou négative';
    END IF;
    -- UNION déduplique les identifiants : même un cycle ne fait pas boucler le contrôle.
    IF (WITH RECURSIVE accessibles AS (
            SELECT id_categorie FROM categories_batiments WHERE id_parent IS NULL
            UNION
            SELECT c.id_categorie FROM categories_batiments c
            JOIN accessibles a ON c.id_parent = a.id_categorie
        ) SELECT COUNT(*) FROM accessibles)
       <> (SELECT COUNT(*) FROM categories_batiments) THEN
        RAISE EXCEPTION 'Hiérarchie invalide : des catégories sont inaccessibles depuis une racine';
    END IF;
END $$;

SELECT 'ressources' AS table_verifiee, COUNT(*) AS lignes FROM ressources
UNION ALL SELECT 'categories_batiments', COUNT(*) FROM categories_batiments
UNION ALL SELECT 'batiments', COUNT(*) FROM batiments
UNION ALL SELECT 'evenements_production', COUNT(*) FROM evenements_production;

SELECT MIN(date_evenement) AS debut, MAX(date_evenement) AS fin,
       COUNT(DISTINCT DATE_TRUNC('month', date_evenement)) AS mois_avec_activite
FROM evenements_production;
