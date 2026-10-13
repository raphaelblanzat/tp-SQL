# Journal de bord du projet SQL

## 1. Présentation du projet

Le projet consiste à concevoir une base de données PostgreSQL pour un jeu vidéo de gestion et d'économie. Le joueur peut développer son activité grâce à différents bâtiments qui produisent des ressources.

La base de données permet de représenter les ressources disponibles, les catégories de bâtiments, les bâtiments construits et les événements de production enregistrés au cours du temps.

L'objectif est également de pouvoir exploiter les données grâce à des requêtes SQL analytiques afin d'étudier l'évolution de la production et de comparer les performances des bâtiments et des ressources.

## 2. Choix de conception

### Table `ressources`

Cette table contient les différentes ressources du jeu, comme le bois, la pierre, le fer ou la nourriture.

Chaque ressource possède un identifiant, un nom et une unité. Le nom est unique afin d'éviter d'enregistrer plusieurs fois la même ressource.

### Table `categories_batiments`

Cette table permet de classer les bâtiments par catégories.

La colonne `id_parent` fait référence à une autre catégorie de la même table. Cette relation permet de créer une hiérarchie entre les catégories et de représenter des sous-catégories. Les catégories principales peuvent ne pas avoir de parent.

### Table `batiments`

Cette table contient les différents bâtiments du jeu. Chaque bâtiment possède un identifiant, un nom, un niveau et une catégorie.

La clé étrangère vers `categories_batiments` permet de rattacher chaque bâtiment à une catégorie existante. Une contrainte `CHECK` impose un niveau strictement positif.

### Table `evenements_production`

Cette table enregistre les événements de production. Chaque événement est associé à un bâtiment et à une ressource, avec une date et une quantité produite.

La date permet de suivre la production dans le temps. La quantité doit être strictement positive afin d'éviter les événements de production invalides.

## 3. Contraintes et intégrité des données

Plusieurs contraintes ont été mises en place pour garantir la cohérence de la base de données :

- Les clés primaires identifient chaque ligne de manière unique.
- Les clés étrangères assurent la cohérence des relations entre les tables.
- Les contraintes `NOT NULL` imposent la présence des informations indispensables.
- La contrainte `UNIQUE` sur le nom des ressources évite les doublons.
- Les contraintes `CHECK` sur le niveau des bâtiments et la quantité produite empêchent certaines valeurs invalides.

Ces contraintes permettent de limiter les erreurs lors de l'insertion des données.

## 4. Données de test

Le fichier `seed.sql` contient les données initiales nécessaires pour tester la base de données :

- 20 ressources ;
- 15 catégories de bâtiments ;
- 19 bâtiments ;
- 100 événements de production.

Les événements de production sont répartis sur cinq mois, de janvier à mai 2024. Cette période permet de disposer de suffisamment de données pour effectuer des analyses temporelles.

Les données sont fictives et servent à tester le fonctionnement de la base ainsi que les futures requêtes analytiques.

## 5. Difficultés rencontrées

La création des tables a nécessité de respecter l'ordre des relations entre elles. Les tables référencées doivent exister avant de pouvoir insérer les données qui dépendent de ces relations.

L'insertion des données a également demandé de vérifier la cohérence des identifiants utilisés dans les clés étrangères, notamment entre les bâtiments et les événements de production.

Enfin, les scripts d'insertion doivent être exécutés avec attention : si les mêmes données sont insérées plusieurs fois, des erreurs de clés primaires peuvent apparaître. Il faut donc vérifier les données déjà présentes avant de relancer les insertions.

## 6. Résultats des requêtes

Résultats relevés sur le jeu de données corrigé, après exécution des 13 requêtes.

| Requête | Ce qu'elle apprend sur les données |
|---|---|
| Q1 | Pour le bois, l'entrepôt est premier avec 4 600 m³, devant la scierie avec 600 m³. |
| Q2 | Dans les catégories du jeu de données, beaucoup de couples catégorie/ressource n'ont qu'un producteur : le top 3 retourne alors moins de trois lignes. |
| Q3 | Le cumul de bois atteint 5 200 m³ à la fin des événements de mai. |
| Q4 | Le bois passe de 1 000 m³ en janvier à 1 020 en février, soit +2 %. Le premier mois n'a pas de pourcentage de comparaison. |
| Q5 | L'entrepôt fournit 88,46 % du bois et la scierie 11,54 % ; les parts sont calculées au sein d'une même ressource. |
| Q6 | La moyenne mobile du bois vaut 1 020 m³ en mars, moyenne de janvier (1 000), février (1 020) et mars (1 040). |
| Q7 | L'entrepôt, la fonderie, le marché et la maison dépassent la moyenne des producteurs de leur ressource respective. |
| Q8 | Les 15 catégories sont accessibles depuis la racine Ressources ; la branche Scierie descend jusqu'au niveau 4. |
| Q9 | Juin à décembre 2024 n'ont aucune production ; les ressources sans événements restent également visibles à zéro. |
| Q10 | Pour la scierie et le bois, le tableau affiche 100, 110, 120, 130 puis 140 m³ de janvier à mai. |
| Q11 | Le bois a deux sous-totaux de catégories et un total ressource de 5 200 m³ ; les lignes de synthèse sont libellées. |
| Q12 | Moyenne et médiane sont égales pour chaque couple bâtiment/ressource du jeu fourni (par exemple 120 m³ pour la scierie). Les séries sont symétriques et régulières : aucune des deux mesures ne représente mieux ces données. En présence de valeurs extrêmes, la médiane serait moins sensible. |
| Q13 | Le cumul de bois reste à 5 200 m³ après mai ; la moyenne mobile diminue avec les mois vides et atteint zéro en août. |

## 7. Relecture et corrections du 13 octobre 2026

Relecture réalisée avec l'aide de Codex, à partir du sujet du TP2 présent sur le Bureau.

- Les scripts initiaux s'exécutaient et les effectifs respectaient le palier 1.
- Cinq événements de poisson étaient rattachés au puits de pétrole : ils ont été réaffectés à la pêcherie. Le nombre d'événements et leurs quantités sont conservés.
- Le chargement des données est maintenant atomique grâce à `BEGIN` et `COMMIT`.
- Les totaux, classements, parts et statistiques respectent désormais les unités : chaque analyse est partitionnée ou groupée par ressource et affiche son unité. Un total de kg, litres et m³ n'avait pas de sens métier.
- Les calculs mensuels Q4 et Q6 incluent les mois sans activité pour comparer de véritables mois consécutifs.
- Q10 affiche zéro pour les mois vides. Q11 utilise `GROUPING` pour nommer les sous-totaux et les identifiants pour distinguer les noms identiques.
- `verification.sql` ajoute des contrôles reproductibles sur les exigences de données et l'accessibilité de la hiérarchie.

## 8. Vérifications exécutées

Les scripts ont été exécutés avec **PGlite**, un moteur PostgreSQL embarqué, dans une base temporaire. Le serveur PostgreSQL/pgAdmin utilisé pour l'oral n'a pas été lancé sur ce Mac.

- Exécution du schéma, des données, du fichier de vérification et des 13 requêtes.
- Vérification des 100 événements sur cinq mois, des effectifs des tables et des 15 catégories accessibles.
- Vérification des parts de production, des totaux par ressource et des libellés de sous-totaux.
- Retrait temporaire des événements de février : Q4 conserve février à zéro, affiche −100 % puis `NULL` lors de la reprise depuis zéro ; Q6 calcule la moyenne de mars sur les trois mois (680 m³ pour le bois).
- Création temporaire de noms identiques : les bâtiments et catégories restent distincts dans Q11.
- Tentatives d'insertions invalides : les contraintes UNIQUE, CHECK, FOREIGN KEY et NOT NULL rejettent les données attendues.
- Création temporaire d'un cycle de catégories : `verification.sql` le détecte. Les modifications de ces scénarios ont été annulées.

## 9. Limites et préparation de l'oral

Le jeu de données est volontairement simple : progression régulière, cinq mois actifs et plusieurs groupes avec un seul producteur. Il permet d'expliquer les techniques, mais ne représente pas une économie réaliste complète. Aucun prix ne permet de convertir toutes les ressources en une valeur monétaire commune.

Chaque membre doit relire les commentaires et savoir expliquer les requêtes ligne par ligne, notamment `PARTITION BY`, la différence entre agrégation et fenêtre, le calendrier complété par `LEFT JOIN`, et la récursivité. Préparer Q5, Q8 et Q13 pour la démonstration, puis charger les fichiers sur l'ordinateur de l'oral avec les commandes du README.
