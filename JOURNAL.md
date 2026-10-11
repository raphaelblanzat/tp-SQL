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

## 6. Analyses SQL prévues

Le projet prévoit plusieurs analyses à partir des événements de production :

- Classer les bâtiments ou les ressources selon leur production.
- Identifier les meilleurs éléments dans différents groupes.
- Calculer des totaux cumulés au fil du temps.
- Étudier l'évolution de la production entre plusieurs périodes.
- Comparer les résultats à des moyennes et calculer des indicateurs statistiques.
- Repérer les périodes sans activité.
- Construire des synthèses permettant de suivre l'économie du jeu.

Ces analyses doivent permettre de mieux comprendre l'évolution de la production et de démontrer l'utilisation de fonctionnalités avancées de PostgreSQL.

## 7. Bilan

La première étape du projet a permis de construire une base de données relationnelle cohérente, avec quatre tables liées entre elles, des contraintes d'intégrité et un jeu de données de test.

La suite du travail consiste à développer et tester les requêtes analytiques, puis à compléter les fonctionnalités avancées demandées dans le sujet du TP.

Le projet permet de mettre en pratique la conception d'une base relationnelle, la gestion des relations entre les tables et l'utilisation de SQL pour analyser des données.
