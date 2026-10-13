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

Le chargement de `seed.sql` utilise une transaction : une erreur annule toutes les insertions. Il doit être exécuté dans une base vide, après `schema.sql`. Le relancer sur les mêmes données provoque une erreur de clé primaire ; pour refaire la démonstration, créez une nouvelle base dédiée.

## Objectif analytique

Cette base de données sert de support à des requêtes SQL analytiques permettant notamment de :

- Classer les bâtiments selon leur production.
- Comparer la production des ressources.
- Calculer des cumuls de production.
- Étudier l'évolution de la production au fil du temps.
- Analyser les performances des bâtiments et des catégories.

Le projet permet ainsi de mettre en pratique la conception relationnelle, les contraintes d'intégrité et les fonctions analytiques de PostgreSQL.

## Exécution et vérification avec psql

Depuis le dossier du dépôt, avec un serveur PostgreSQL démarré et un utilisateur autorisé à créer une base :

```sh
createdb jeu_gestion
psql -X -v ON_ERROR_STOP=1 -d jeu_gestion -f schema.sql
psql -X -v ON_ERROR_STOP=1 -d jeu_gestion -f seed.sql
psql -X -v ON_ERROR_STOP=1 -d jeu_gestion -f verification.sql
psql -X -v ON_ERROR_STOP=1 -d jeu_gestion -f requetes.sql
```

Si `jeu_gestion` existe déjà, choisissez un nouveau nom dans ces commandes. Dans pgAdmin, exécutez les quatre fichiers SQL dans le même ordre. `verification.sql` contrôle les effectifs, la couverture temporelle, les quantités et la hiérarchie sans modifier les données.

Résultats attendus : **20 ressources, 15 catégories, 19 bâtiments et 100 événements**, du 1er janvier au 20 mai 2024, sur cinq mois distincts.

## Requêtes et correspondance avec les paliers

| Palier | Requêtes | Techniques |
|---|---|---|
| 1 | `schema.sql`, `seed.sql`, `verification.sql` | Clés étrangères, contraintes, hiérarchie et données |
| 2 | Q1 à Q6 | RANK partitionné, top 3, cumul, LAG en %, part du total, moyenne mobile |
| 3 | Q2 et Q7 ; Q8 ; Q9 | Deux analyses avec CTE enchaînées ; récursivité ; calendrier et LEFT JOIN |
| 4 | Q10 à Q13 | FILTER, ROLLUP et GROUPING, médiane, tableau de bord |

Q2 répond aussi au palier 3 : sa seconde CTE utilise bien le résultat de la première. Chaque requête est autonome après le chargement du schéma et des données.

## Interprétation et limites des données

- Les quantités sont analysées **par ressource**, avec leur unité : additionner des litres, des kg et des m³ ne donnerait pas un indicateur métier interprétable. Même deux ressources en kg restent séparées.
- Q1 et Q2 utilisent `RANK` : deux bâtiments à égalité ont le même rang. Un top 3 peut donc contenir plus de trois lignes. Les partitions reposent sur les identifiants, pas sur les noms.
- Q4 et Q6 complètent les mois manquants entre le premier et le dernier événement. Une absence de production vaut zéro. Une évolution depuis zéro est indéfinie et affiche `NULL`.
- Q9 et Q13 portent explicitement sur toute l'année **2024**, y compris juin à décembre sans activité. Q10 présente janvier à mai 2024.
- La moyenne mobile porte sur trois mois calendaires, ou un/deux mois au début de la série.
- Le jeu de données reste fictif et régulier. Certains groupes n'ont qu'un producteur ; des bâtiments comme l'entrepôt représentent des entrées de stock. La production de poisson auparavant attribuée au puits de pétrole est rattachée à la pêcherie.
- La clé étrangère hiérarchique ne suffit pas à interdire les cycles : `verification.sql` détecte les catégories inaccessibles depuis les racines. Exécutez ce contrôle après une modification des catégories.

## Démonstration orale suggérée

1. Q5 : le bois est réparti entre l'entrepôt (88,46 %) et la scierie (11,54 %). Expliquer la somme par bâtiment puis la somme de fenêtre par ressource.
2. Q8 : suivre le chemin `Ressources > Industrie > Transformation > Scierie`. Expliquer la racine puis l'étape récursive.
3. Q13 : suivre les 5 200 m³ de bois cumulés en mai, puis les mois sans production. Expliquer le calendrier, le LEFT JOIN, le cumul et la fenêtre de trois mois.

Les observations pour toutes les requêtes et les vérifications réalisées figurent dans `JOURNAL.md`.
