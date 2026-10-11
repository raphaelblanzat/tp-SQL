# Jeu de gestion — Base de données

## Présentation du projet

Ce projet consiste à concevoir une base de données PostgreSQL pour un jeu vidéo solo de gestion avec une économie virtuelle.

Le jeu repose sur différentes ressources, comme le bois, la pierre, le fer, l'or ou la nourriture. Le joueur peut gérer des bâtiments qui produisent ou extraient ces ressources. Les événements de production sont enregistrés afin de pouvoir analyser l'évolution de la production au fil du temps.

## Schéma de la base de données

La base de données contient quatre tables principales.

### 1. `ressources`

Cette table contient les différentes ressources disponibles dans le jeu.

- `id_ressource` : identifiant unique de la ressource.
- `nom` : nom de la ressource, qui doit être unique.
- `unite` : unité de mesure de la ressource.

### 2. `categories_batiments`

Cette table permet de classer les bâtiments par catégories et sous-catégories.

- `id_categorie` : identifiant unique de la catégorie.
- `nom` : nom de la catégorie.
- `id_parent` : référence à une autre catégorie pour représenter une hiérarchie. Cette valeur peut être `NULL` pour une catégorie principale.

La clé étrangère `id_parent` référence la table `categories_batiments` elle-même.

### 3. `batiments`

Cette table contient les bâtiments disponibles dans le jeu.

- `id_batiment` : identifiant unique du bâtiment.
- `nom` : nom du bâtiment.
- `niveau` : niveau du bâtiment, obligatoirement supérieur à zéro.
- `id_categorie` : référence à la catégorie du bâtiment.

Chaque bâtiment appartient à une catégorie existante.

### 4. `evenements_production`

Cette table enregistre les événements de production réalisés dans le jeu.

- `id_evenement` : identifiant unique de l'événement.
- `id_batiment` : référence au bâtiment concerné.
- `id_ressource` : référence à la ressource produite.
- `date_evenement` : date et heure de l'événement.
- `quantite` : quantité produite, obligatoirement positive.

Chaque événement est associé à un bâtiment et à une ressource.

## Relations entre les tables

- Une catégorie peut contenir plusieurs bâtiments.
- Une catégorie peut avoir une catégorie parente.
- Un bâtiment peut être associé à plusieurs événements de production.
- Une ressource peut apparaître dans plusieurs événements de production.
- Chaque événement de production référence un bâtiment et une ressource existants.

Les relations entre les tables sont assurées par des clés étrangères (`FOREIGN KEY`). Les identifiants uniques sont définis avec des clés primaires (`PRIMARY KEY`).

## Contraintes et intégrité des données

La base de données utilise plusieurs contraintes pour garantir la cohérence des données :

- **PRIMARY KEY** : garantit l'identification unique de chaque ligne.
- **FOREIGN KEY** : garantit la cohérence des relations entre les tables.
- **NOT NULL** : empêche l'absence de valeurs pour les colonnes obligatoires.
- **UNIQUE** : empêche les doublons dans les noms de ressources.
- **CHECK** : impose un niveau de bâtiment supérieur à zéro et une quantité de production strictement positive.

## Contenu des données

Le jeu de données initial contient :

- 20 ressources.
- 15 catégories de bâtiments.
- 19 bâtiments.
- 100 événements de production répartis sur cinq mois, de janvier à mai 2024.

Ces données permettent de réaliser des requêtes analytiques sur la production des ressources et l'activité des bâtiments.

## Installation et chargement

La base de données utilise PostgreSQL.

### Prérequis

- PostgreSQL installé.
- Une base de données créée pour le projet.

### Étapes de chargement

1. Créer une base de données nommée `jeu_gestion`.
2. Ouvrir l'outil de requêtes de pgAdmin et se connecter à cette base.
3. Exécuter le fichier `schema.sql` pour créer les tables.
4. Exécuter le fichier `seed.sql` pour insérer les données initiales.

**Important :** le schéma doit être créé avant l'insertion des données, car les tables et leurs relations doivent exister au préalable.

Les fichiers d'insertion ne doivent pas être exécutés plusieurs fois sur les mêmes données, car les identifiants déjà présents peuvent provoquer des erreurs de clés primaires en double.

## Objectif analytique

Cette base de données sert de support à des requêtes SQL analytiques permettant notamment de :

- Classer les bâtiments selon leur production.
- Comparer la production des ressources.
- Calculer des cumuls de production.
- Étudier l'évolution de la production au fil du temps.
- Analyser les performances des bâtiments et des catégories.

Le projet permet ainsi de mettre en pratique la conception relationnelle, les contraintes d'intégrité et les fonctions analytiques de PostgreSQL.